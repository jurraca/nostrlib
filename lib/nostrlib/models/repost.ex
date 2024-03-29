defmodule Nostrlib.Repost do
  @moduledoc """
  Repost event struct and manipulation functions
  """
  @derive Jason.Encoder
  defstruct [:event, :relays]

  alias __MODULE__
  alias Nostrlib.{Event, Utils}
  alias Nostrlib.Keys.PublicKey

  @type t :: %__MODULE__{}

  @repost_kind 6

  @doc """
  Convert a repost model to a nostr event
  """
  @spec to_event(Repost.t(), PublicKey.id()) :: {:ok, Event.t()} | {:error, String.t()}
  def to_event(%Repost{event: event, relays: relays}, delete_pubkey) do
    with {:ok, tags} <- create_tags(event),
         {:ok, content} <- content_from_event(event, relays) do
      {
        :ok,
        %Event{
          Event.create(@repost_kind, content, delete_pubkey)
          | tags: tags
        }
      }
    else
      {:error, message} ->
        {:error, message}
    end
  end

  @spec create_tags(Event.t()) :: {:ok, list()} | {:error, String.t()}
  defp create_tags(%Event{id: id, pubkey: pubkey}) do
    case to_hex(id) do
      {:ok, hex_event_id} ->
        {
          :ok,
          [
            ["e", hex_event_id],
            ["p", Utils.to_hex(pubkey)]
          ]
        }

      {:error, message} ->
        {:error, message}
    end
  end

  defp to_hex(event_id) do
    with {:ok, binary_event_id} <- Event.Id.to_binary(event_id),
         {:ok, _, hex_event_id} <- Utils.to_hex(binary_event_id) do
      {:ok, hex_event_id}
    else
      {:error, message} ->
        {:error, message}
    end
  end

  @spec content_from_event(Event.t(), list()) :: {:ok, String.t()} | {:error, String.t()}
  defp content_from_event(%Event{} = event, relays) do
    %{
      content: event.content,
      created_at: DateTime.to_unix(event.created_at),
      id: event.id,
      kind: event.kind,
      pubkey: Utils.to_hex(event.pubkey),
      relays: relays,
      sig: Utils.to_hex(event.sig),
      tags: event.tags
    }
    |> Jason.encode()
  end
end
