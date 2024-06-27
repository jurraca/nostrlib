defmodule Nostrlib.Note do
  @moduledoc """
  Create a kind 1 note
  """

  @derive Jason.Encoder
  defstruct [:content]

  alias Nostrlib.{Event, Utils}
  alias Nostrlib.Keys.{PublicKey, PrivateKey}

  @type t :: %__MODULE__{}

  @doc """
  Creates a new nostr note
  """
  @spec create(String.t(), PublicKey.t()) :: {:ok, Event.t()} | {:error, String.t()}
  def create(content, pubkey) when is_binary(content) do
    hex_pubkey = Utils.to_hex(pubkey)
    %__MODULE__{content: content} |> Event.create(hex_pubkey)
  end

  def create_serialized(content, privkey) when is_binary(privkey) do
    {:ok, pk} = PrivateKey.from_binary(privkey)
    create_serialized(content, pk)
  end

  @spec create_serialized(String.t(), map()) :: {:ok, String.t()} | {:error, String.t()}
  def create_serialized(content, privkey) do
    {:ok, pubkey} = PublicKey.from_private_key(privkey)
    create(content, pubkey) |> Event.sign_and_serialize(privkey)
  end
end
