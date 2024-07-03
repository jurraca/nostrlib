defmodule Nostrlib.Note do
  @moduledoc """
  Create a kind 1 note
  """

  use Flint

  embedded_schema do
    field :content, :string
  end

  @kind 1

  alias Nostrlib.{Event, Utils}
  alias Nostrlib.Keys.{PublicKey, PrivateKey}

  @spec to_event(%__MODULE__{}, PublicKey.t()) :: Event.t()
  def to_event(%__MODULE__{content: content}, hex_pubkey) do
    Event.create(@kind, content, hex_pubkey)
  end

  def to_event_serialized(%__MODULE__{} = note, privkey) when is_binary(privkey) do
    {:ok, pk} = PrivateKey.from_binary(privkey)
    to_event_serialized(note, pk)
  end

  @spec to_event_serialized(%__MODULE__{}, map()) :: {:ok, String.t()} | {:error, String.t()}
  def to_event_serialized(note, privkey) do
    with {:ok, pubkey} <- PublicKey.from_private_key(privkey),
        hex_pubkey <- Utils.to_hex(pubkey) do
      to_event(note, hex_pubkey) |> Event.sign_and_serialize(privkey)
    end
  end
end
