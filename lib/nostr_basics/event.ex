defmodule NostrBasics.Event do
  @moduledoc """
  Represents the basic structure of anything that's being sent to/from relays
  """

  require Logger

  @derive Jason.Encoder
  defstruct [:id, :pubkey, :created_at, :kind, :tags, :content, :sig]

  alias NostrBasics.Utils
  alias NostrBasics.Keys.{PrivateKey, PublicKey}
  alias NostrBasics.{ContactList, Note, Profile}
  alias Bitcoinex.Secp256k1.{Point, Schnorr, Signature}
  alias Bitcoinex.Secp256k1.PrivateKey, as: PrivKey

  @profile_kind 0
  @note_kind 1
  @contact_kind 3
  @delete_kind 5
  @repost_kind 6
  @reaction_kind 7

  @doc """
  Create an event.
  """
  @spec create(integer(), String.t() | nil, <<_::256>>) :: Event.t()
  def create(kind, content, hex_pubkey, opts \\ []) when is_integer(kind) do
    tags = if(opts[:tags], do: opts[:tags], else: [])
    create(%{kind: kind, pubkey: hex_pubkey, content: content, tags: tags})
  end

  def create(%{kind: _, pubkey: _, content: _} = event_map) do
    %__MODULE__{}
    |> Map.merge(event_map)
    |> add_id()
  end

  def create(%Note{content: content}, privkey) do
    create(@note_kind, content, privkey)
  end

  def create(%Profile{} = profile, privkey) do
    create(@profile_kind, profile, privkey)
  end

  def create(%ContactList{} = contact_list, privkey) do
    {:ok, content, tags} = ContactList.get_content_and_tags(contact_list)
    create(@contact_kind, contact_list, privkey, tags: tags)
  end

  def sign_event(%__MODULE__{id: id} = event, %PrivKey{} = privkey) do
    aux_bytes = :crypto.strong_rand_bytes(32) |> :binary.decode_unsigned()
    id_bin = id |> Utils.from_hex() |> :binary.decode_unsigned()
    # {:ok, private_key}  = PrivateKey.from_binary(privkey)
    case Schnorr.sign(privkey, id_bin, aux_bytes) do
      {:ok, sig} ->
        serialized_sig = serialize_sig!(sig)
        {:ok, %{event | sig: serialized_sig}}

      {:error, message} when is_atom(message) ->
        {:error, Atom.to_string(message)}
    end
  end

  def sign_and_serialize(%__MODULE__{} = event, %PrivKey{} = privkey) do
    case sign_event(event, privkey) do
      {:ok, event} -> Jason.encode(["EVENT", event])
      {:error, message} when is_atom(message) -> {:error, Atom.to_string(message)}
    end
  end

  @doc """
  The Nostr encoding scheme. Takes fields as an array and json encodes them.
  """
  @spec nostr_encode(%__MODULE__{}) :: String.t()
  def nostr_encode(%__MODULE__{
        pubkey: hex_pubkey,
        created_at: created_at,
        kind: kind,
        tags: tags,
        content: content
      }) do
    tags = if(tags, do: tags, else: [])

    [
      0,
      hex_pubkey,
      created_at,
      kind,
      tags,
      content
    ]
    |> Utils.json_encode()
  end

  @doc """
  Adds an ID to an event that doesn't have one
  """
  @spec add_id(%__MODULE__{}) :: %__MODULE__{}
  def add_id(%__MODULE__{created_at: nil} = event) do
    event_with_ts = %{event | created_at: DateTime.utc_now() |> DateTime.to_unix()}
    add_id(event_with_ts)
  end

  def add_id(%__MODULE__{created_at: _} = event_with_ts) do
    id = encode_id(event_with_ts)
    %{event_with_ts | id: id}
  end

  @doc """
  Creates an ID for an event from its fields.
  """
  @spec encode_id(Event.t()) :: String.t()
  def encode_id(%__MODULE__{} = event) do
    case nostr_encode(event) do
      {:ok, encoded} -> encoded |> Utils.sha256() |> Utils.to_hex()
      {:error, msg} -> {:error, msg}
    end
  end

  @doc """
  Converts a NIP-01 JSON string into a %Event{}
  """
  @spec decode(Map.t()) :: {:ok, %__MODULE__{}} | {:error, String.t()}
  def decode(event) when is_map(event) do
    if validate_event(event) do
      atom_map = Enum.map(event, fn {k, v} -> {String.to_atom(k), v} end)
      {:event, Map.merge(%__MODULE__{}, atom_map)}
    else
      Logger.warn("Could not validate event #{event.id}.")
      {:error, :invalid_event}
    end
  end

  @spec decode!(String.t()) :: %__MODULE__{}
  def decode!(string_event) do
    m = Utils.decode_json(string_event)

    case decode(m) do
      {:ok, event} -> event
      {:error, message} -> raise message
    end
  end

  @doc """
  Encodes an event key into the nevent format
  """
  @spec to_nevent(%__MODULE__{}) :: binary()
  def to_nevent(%__MODULE__{id: nil} = event) do
    id = encode_id(event)
    Bech32.encode("nevent", id)
  end

  def to_nevent(%__MODULE__{id: id}), do: Bech32.encode("nevent", id)

  @spec serialize_sig!(%Signature{}) :: binary()
  def serialize_sig!(sig) do
    sig
    |> Signature.serialize_signature()
    |> Base.encode16(case: :lower)
  end

  @spec validate_event(%__MODULE__{}) :: :ok | {:error, String.t()}
  def validate_event(%__MODULE__{} = event) do
    with true <- validate_id(event),
         true <- validate_signature(event) do
      true
    else
      {:error, message} -> {:error, message}
    end
  end

  @spec validate_id(%__MODULE__{}) :: :ok | {:error, String.t()}
  def validate_id(%__MODULE__{id: id} = event) do
    case id == encode_id(event) do
      true -> true
      false -> {:error, "generated ID and the one in the event don't match"}
    end
  end

  @moduledoc """
  Check that an event's signature is valid for the event.
  """
  @spec validate_signature(%__MODULE__{}) :: :ok | {:error, atom()}
  def validate_signature(%__MODULE__{id: id, sig: sig, pubkey: pubkey}) do
    with id_int <- id |> Utils.from_hex() |> :binary.decode_unsigned(),
         {:ok, parsed_sig} <- Signature.parse_signature(sig) do
      # Utils.from_hex(pubkey)
      case Point.lift_x(pubkey) do
        {:ok, lifted_pubkey} ->
          Schnorr.verify_signature(lifted_pubkey, id_int, parsed_sig)

        {:error, _} = err ->
          err
      end
    end
  end
end
