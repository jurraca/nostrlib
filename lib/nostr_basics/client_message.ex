defmodule NostrBasics.ClientMessage do
  @moduledoc """
  A message from a client to a relay

  Specification here:

  https://github.com/nostr-protocol/nips/blob/master/01.md#from-client-to-relay-sending-events-and-creating-subscriptions
  """

  alias NostrBasics.{Event, Filter, CloseRequest}

  @doc """
  Converts a client message in string format to the internal struct
  """
  @spec parse(String.t()) ::
          {:event, Event.t()}
          | {:req, list(Filter.t())}
          | {:close, CloseRequest.t()}
          | {:unknown, String.t()}
  def parse(message) do
    case Jason.decode(message) do
      {:ok, encoded_message} ->
        decode(encoded_message)

      {:error, %Jason.DecodeError{position: position, token: token}} ->
        {:error, "error decoding JSON at position #{position}: #{token}"}
    end
  end

  @spec decode(list()) ::
          {:event, Event.t()}
          | {:req, list(Filter.t())}
          | {:close, CloseRequest.t()}
          | {:unknown, String.t()}
  def decode(["EVENT", encoded_event]) do
    {:event, Event.decode(encoded_event)}
  end

  def decode(["REQ" | [subscription_id | requests]]) do
    {:req, Enum.map(requests, &Filter.decode(&1, subscription_id))}
  end

  def decode(["CLOSE", subscription_id]) do
    {:close, %CloseRequest{subscription_id: subscription_id}}
  end

  def decode(_unknown_message) do
    {:unknown, "Unknown nostr message type"}
  end
end
