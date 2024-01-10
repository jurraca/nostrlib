defmodule NostrBasics.RelayMessage do
  @moduledoc """
  A message from a relay to a client

  Specifications here:

  - https://github.com/nostr-protocol/nips/blob/master/01.md#from-relay-to-client-sending-events-and-notices
  - https://github.com/nostr-protocol/nips/blob/master/15.md
  - https://github.com/nostr-protocol/nips/blob/master/20.md
  """

  alias NostrBasics.Event

  @doc """
  Converts a client message in string format to the actual related Elixir structure
  """
  @spec parse(String.t()) ::
          {:event, String.t(), Event.t()}
          | {:notice, String.t()}
          | {:end_of_stored_events, String.t()}
          | {:ok, String.t(), boolean(), String.t()}
          | {:unknown, String.t()}
          | {:json_error, String.t()}
  def parse(message) do
    case Jason.decode(message) do
      {:ok, encoded_message} ->
        decode(encoded_message)

      {:error, %Jason.DecodeError{position: position, token: token}} ->
        {:json_error, "error decoding JSON at position #{position}: #{token}"}
    end
  end

  @spec decode(list()) ::
          {:event, String.t(), Event.t()}
          | {:notice, String.t()}
          | {:end_of_stored_events, String.t()}
          | {:ok, String.t(), boolean(), String.t()}
          | {:unknown, String.t()}
  def decode(["EVENT", subscription_id, encoded_event]) do
    case Event.decode(encoded_event) do
      {:ok, event} -> {:event, subscription_id, event}
      {:error, reason} -> {:error, reason}
    end
  end

  def decode(["NOTICE", message]) do
    {:notice, message}
  end

  def decode(["EOSE", subscription_id]) do
    {:end_of_stored_events, subscription_id}
  end

  def decode(["OK", event_id, success?, message]) do
    {:ok, event_id, success?, message}
  end

  def decode(_unknown_message) do
    {:unknown, "Unknown nostr message type"}
  end
end
