defmodule Nostrlib.Note do
  @moduledoc """
  Create a kind 1 note
  """

  @derive Jason.Encoder
  defstruct [:content]

  alias Nostrlib.Event
  alias Nostrlib.Keys.PublicKey

  @type t :: %__MODULE__{}

  @doc """
  Creates a new nostr note
  """
  @spec create(String.t(), PrivateKey.id()) :: {:ok, Event.t()} | {:error, String.t()}
  def create(content, privkey) when is_binary(content) do
    %__MODULE__{content: content} |> Event.create(privkey)
  end

  @spec create(String.t(), PrivateKey.id()) :: {:ok, String.t()} | {:error, String.t()}
  def create_serialized(content, privkey) do
    create(content, privkey) |> Event.sign_and_serialize(privkey)
  end
end
