defmodule Nostrlib.Message do
  @moduledoc """
  Parse messages between clients and relays.
  """

  alias Nostrlib.{CloseRequest, Event, Filter, Utils}

  @doc """
  Converts a client message in string format to the internal struct
  """
  def parse(message) do
    case Utils.json_decode(message, keys: :atoms) do
      {:ok, message} -> decode(message)
      {:error, msg} -> {:error, msg}
    end
  end

  ### Clients to relays
  def decode(["EVENT", event]), do: Event.decode(event)

  def decode(["REQ",  sub_id | requests]) do
    {:req, sub_id, Enum.map(requests, &Filter.decode(&1))}
  end

  def decode(["CLOSE", subscription_id]) do
    {:close, %CloseRequest{subscription_id: subscription_id}}
  end

  ### Relays to Clients
  def decode(["EVENT", subscription_id, event]) do
    {:event, subscription_id, event}
  end

  def decode(["NOTICE", message]) when is_binary(message) do
    {:notice, message}
  end

  def decode(["EOSE", subscription_id]) do
    {:end_of_stored_events, subscription_id}
  end

  def decode(["OK", event_id, true, message]) do
    {:ok, event_id, message}
  end

  def decode(["OK", event_id, false, message]) do
    [reason, msg] = String.split(message, ":")

    {:error, event_id,
     "Message not accepted by relay with reason: #{reason} for event #{event_id} with message #{msg}"}
  end

  def decode(["CLOSED", subscription_id, nil]) do
    {:closed, subscription_id}
  end

  def decode(["CLOSED", subscription_id, message]) do
    [reason, msg] = String.split(message, ":")

    {:error,
     "Subscription closed by relay with reason: #{reason} for event #{subscription_id} with message #{msg}"}
  end

  def decode(_unknown_message) do
    {:unknown, "Unknown nostr message type"}
  end
end
