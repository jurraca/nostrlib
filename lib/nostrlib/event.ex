defmodule Nostrlib.Event do
  @moduledoc """
  Create and decode events.

  Main API:
  `create/2` takes a model struct and a hex pubkey.
  `sign_event/2` and `sign_and_serialize/2` both take an Event and Privkey structs.
  `Privkey` is Bitcoinex's `PrivateKey` struct holding an integer.
  """

  use Flint
  require Logger

  alias Nostrlib.Utils
  alias Nostrlib.Event.Tags
  alias Bitcoinex.Secp256k1.{Point, Schnorr, Signature}
  alias Bitcoinex.Secp256k1.PrivateKey, as: PrivKey

  embedded_schema do
     field :id, :string
     field :pubkey, :string
     field :kind, :integer, le: 65535
     field :content, :string
     field :sig, :string
     field :created_at, :integer
     embeds_one :tags, Tags
  end

  @doc """
  Create an event.
  """
  @spec create(integer(), String.t() | nil, <<_::256>>) :: Event.t()
  def create(kind, content, hex_pubkey, opts \\ []) when is_integer(kind) do
    tags = if(opts[:tags], do: opts[:tags], else: [])
    create(%{kind: kind, pubkey: hex_pubkey, content: content, tags: tags})
  end

  def create(%{kind: _, pubkey: _, content: _} = params) do
    new(params) |> add_id()
  end

  @doc """
  Sign an event. It must already have an id to be signed.
  """
  def sign(%__MODULE__{id: id} = event, %PrivKey{} = privkey) do
    aux_bytes = :crypto.strong_rand_bytes(32) |> :binary.decode_unsigned()
    id_bin = id |> Utils.from_hex() |> :binary.decode_unsigned()
    case Schnorr.sign(privkey, id_bin, aux_bytes) do
      {:ok, sig} ->
        serialized_sig = serialize_sig!(sig)
        {:ok, %{event | sig: serialized_sig}}

      {:error, message} ->
        {:error, message}
    end
  end

  def sign_and_serialize(%__MODULE__{} = event, %PrivKey{} = privkey) do
    case sign(event, privkey) do
      {:ok, event} -> encode(event)
      {:error, message} -> {:error, message}
    end
  end

  @doc """
  The Nostr encoding scheme. Takes fields as an array and json encodes them.
  """
  @spec nostr_encode(%__MODULE__{}) :: {:ok, String.t()} | {:error, String.t()}
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
  Adds an ID to an event that doesn't have one.
  If it doesn't have a created_at ts, add it first.
  """
  @spec add_id(%__MODULE__{}) :: %__MODULE__{}
  def add_id(%__MODULE__{created_at: nil} = event) do
    unix_ts_now = DateTime.utc_now() |> DateTime.to_unix()
    %{event | created_at: unix_ts_now} |> add_id()
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

  def encode(%__MODULE__{} = event) do
     Utils.json_encode(["EVENT", event])
  end

  @doc """
  Converts a NIP-01 JSON string into a %Event{}
  """
  @spec decode(Map.t()) :: {:ok, %__MODULE__{}} | {:error, String.t()}
  def decode(event) when is_map(event) do
    case new(event)|> validate_event() do
      {:ok, event} -> {:ok, event}
      {:error, reason} = err ->
          Logger.warning("Could not validate event #{event.id} with reason #{reason}.")
          err
    end
  end

  @spec decode(String.t()) :: {:ok, %__MODULE__{}} | {:error, String.t()}
  def decode(json_string) when is_binary(json_string) do
    case Utils.json_decode(json_string, keys: :atoms) do
        {:ok, ["EVENT", event_map]} -> decode(event_map)
        {:error, msg} -> {:error, msg}
    end
  end

  @spec serialize_sig!(Signature.t{}) :: binary()
  def serialize_sig!(sig) do
    sig
    |> Signature.serialize_signature()
    |> Base.encode16(case: :lower)
  end

  @spec validate_event(Map.t()) :: {:ok, %__MODULE__{}} | {:error, String.t() | Atom.t()}
  def validate_event(%__MODULE__{} = event) do
    with {:ok, _} <- validate_id(event),
         true <- validate_signature(event) do
      {:ok, event}
    else
      {:error, reason}  -> {:error, reason}
    end
  end

  @spec validate_id(%__MODULE__{}) :: {:ok, String.t()} | {:error, String.t()}
  def validate_id(%__MODULE__{id: id} = event) do
    case id == encode_id(event) do
      true -> {:ok, id}
      false -> {:error, "event ID does not match the one provided"}
    end
  end

  @doc """
  Check that an event's signature is valid for the event.
  """
  @spec validate_signature(%__MODULE__{}) :: boolean() | {:error, atom()}
  def validate_signature(%__MODULE__{sig: nil}), do: {:error, "signature field is empty"}
  def validate_signature(%__MODULE__{id: id, sig: sig, pubkey: pubkey}) do
    with id_int <- id |> Utils.from_hex() |> :binary.decode_unsigned(),
         {:ok, parsed_sig} <- Signature.parse_signature(sig) do
      case Point.lift_x(pubkey) do
        {:ok, lifted_pubkey} ->
          Schnorr.verify_signature(lifted_pubkey, id_int, parsed_sig)

        {:error, _} = err ->
          err
      end
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
end
