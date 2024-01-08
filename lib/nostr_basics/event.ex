defmodule NostrBasics.Event do
  @moduledoc """
  Represents the basic structure of anything that's being sent to/from relays
  """

  require Logger

  #@derive Jason.Encoder
  defstruct [:id, :pubkey, :created_at, :kind, :tags, :content, :sig]

  alias Bitcoinex.{Bech32, Utils}
  alias Bitcoinex.Secp256k1.{Point, Schnorr, Signature}

  @doc """
  Create an event.
  """
  @spec create(integer(), String.t() | nil, <<_::256>>) :: Event.t()
  def create(kind, content, pubkey) do
    create(%{kind: kind, pubkey: pubkey, content: content})
  end

  def create(%{kind: _, pubkey: _, content: _} = event_map) do
    %__MODULE__{}
    |> Map.merge(event_map)
    |> add_id
  end

  def sign_event(%__MODULE__{id: id} = event, privkey) do
    aux_bytes = :crypto.strong_rand_bytes(32) |> :binary.decode_unsigned()
    id_bin = Base.decode16!(id, case: :lower) |> :binary.decode_unsigned()

    case Schnorr.sign(privkey, id_bin, aux_bytes) do
      {:ok, sig} ->
        serialized_sig = serialize_sig!(sig)
        {:ok, %{event | sig: serialized_sig}}
      {:error, message} when is_atom(message) -> {:error, Atom.to_string(message)}
    end
  end

  def sign_and_serialize(%__MODULE__{} = event, privkey) do
    case sign_event(event, privkey) do
      {:ok, event} -> Jason.encode(event)
      {:error, message} when is_atom(message) -> {:error, Atom.to_string(message)}
    end
  end

  @doc """
  Converts a NIP-01 JSON string into a %Event{}
  """
  @spec decode(String.t()) :: {:ok, %__MODULE__{}} | {:error, String.t()}
  def decode(json_event) do
    case Jason.decode(json_event) do
      {:ok, event} ->
        {:ok, event}

      {:error, %Jason.DecodeError{position: position, token: token}} ->
        {:error, "error decoding JSON at position #{position}: #{token}"}
    end
  end

  @spec decode!(String.t()) :: %__MODULE__{}
  def decode!(string_event) do
    case decode(string_event) do
      {:ok, event} -> event
      {:error, message} -> raise message
    end
  end

  @doc """
  The Nostr encoding scheme. Takes fields as an array and json encodes them.
  """
  @spec nostr_encode(%__MODULE__{}) :: String.t()
  def nostr_encode(%__MODULE__{
        pubkey: pubkey,
        created_at: created_at,
        kind: kind,
        tags: tags,
        content: content
      }) do
    hex_pubkey = Base.encode16(pubkey, case: :lower)
    timestamp = DateTime.to_unix(created_at)

    [
      0,
      hex_pubkey,
      timestamp,
      kind,
      tags,
      content
    ]
    |> Jason.encode!()
  end

  def decode(event) when is_binary(event), do: Jason.decode(event)

  @doc """
  Adds an ID to an event that doesn't have one
  """
  @spec add_id(%__MODULE__{}) :: %__MODULE__{}
  def add_id(%__MODULE__{created_at: nil} = event) do
    event_with_ts = %{event | created_at: DateTime.utc_now()}
    id = create_id(event_with_ts)
    %{event_with_ts | id: id}
  end

  @doc """
  Creates an ID for an event from its fields.
  """
  @spec create_id(Event.t()) :: String.t()
  def create_id(%__MODULE__{} = event) do
    event
    |> nostr_encode()
    |> Utils.sha256()
    |> Base.encode16(case: :lower)
  end

#  @doc """
#  Encodes an event key into the nevent format
#  """
#  @spec to_nevent(%__MODULE__{}) :: binary()
#  def to_nevent(%__MODULE__{id: nil} = event) do
#    id = create_id(event)
#    Bech32.encode("nevent", id, :bech32)
#  end
#
#  def to_nevent(%__MODULE__{id: id}) do
#    bin = Base.decode16!(id, case: :lower) |> :binary.bin_to_list()
#    Bech32.encode("nevent", bin, :bech32)
#  end

  @spec validate_event(%__MODULE__{}) :: :ok | {:error, String.t()}
  def validate_event(%__MODULE__{} = event) do
    with :ok <- validate_id(event),
         :ok <- validate_signature(event) do
      :ok
    else
      {:error, message} -> {:error, message}
    end
  end

  @spec validate_id(%__MODULE__{}) :: :ok | {:error, String.t()}
  def validate_id(%__MODULE__{id: id} = event) do
    case id == create_id(event) do
      true -> :ok
      false -> {:error, "generated ID and the one in the event don't match"}
    end
  end

  @spec serialize_sig!(binary()) :: binary()
  def serialize_sig!(sig) when is_binary(sig) do
    sig
    |> Signature.serialize_signature()
    |> Base.encode16(case: :lower)
  end

  @spec validate_signature(%__MODULE__{}) :: :ok | {:error, atom()}
  def validate_signature(%__MODULE__{id: id, sig: sig, pubkey: pubkey}) do
    case Point.lift_x(pubkey) do
      {:ok, lifted_pubkey} -> Schnorr.verify_signature(lifted_pubkey, id, sig)
      {:error, _} = err -> err
    end
  end
end
