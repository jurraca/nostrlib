defmodule Nostrlib.Reaction do
  @moduledoc """
  Reaction struct and manipulation functions

  Likes are fiat.
  """
  @derive Jason.Encoder
  defstruct [:event_id, :event_pubkey, :content]

  alias __MODULE__
  alias Nostrlib.{Event, Utils}
  alias Nostrlib.Keys.PublicKey

  @type t :: %__MODULE__{}
  @reaction_kind 7

  @doc """

  """
  @spec to_event(Reaction.t(), PublicKey.id()) :: {:ok, Event.t()} | {:error, String.t()}
  def to_event(
        %Reaction{event_id: event_id, event_pubkey: event_pubkey, content: content},
        reaction_pubkey
      ) do
    case create_tags(event_id, event_pubkey) do
      {:ok, tags} ->
        {
          :ok,
          %Event{
            Event.create(@reaction_kind, content, reaction_pubkey)
            | tags: tags
          }
        }

      {:error, message} ->
        {:error, message}
    end
  end

  @spec create_tags(Event.id(), PublicKey.id()) :: {:ok, list()} | {:error, String.t()}
  defp create_tags(event_id, pubkey) do
    with {:ok, binary_pubkey} <- PublicKey.to_binary(pubkey),
         {:ok, binary_event_id} <- Event.Id.to_binary(event_id),
         {:ok, _, hex_event_id} <- Utils.to_hex(binary_event_id) do
      hex_pubkey = Utils.to_hex(binary_pubkey)

      {
        :ok,
        [
          ["e", hex_event_id],
          ["p", hex_pubkey]
        ]
      }
    else
      {:error, message} ->
        {:error, message}
    end
  end
end
