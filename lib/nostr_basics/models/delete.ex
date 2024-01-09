defmodule NostrBasics.Delete do
  @moduledoc """
  Delete event struct and manipulation functions
  """

  defstruct [:note, event_ids: []]

  alias __MODULE__
    alias NostrBasics.{Event, Utils}
  alias NostrBasics.Keys.PublicKey

  @type t :: %__MODULE__{}

  @delete_kind 5

  @doc """
  Convert a delete model to a nostr event
  """
  @spec to_event(Delete.t(), PublicKey.id()) :: {:ok, Event.t()} | {:error, String.t()}
  def to_event(
        %Delete{event_ids: event_ids, note: note},
        delete_pubkey
      ) do
    case create_tags(event_ids) do
      {:ok, tags} ->
        {
          :ok,
          %Event{
            Event.create(@delete_kind, note, delete_pubkey)
            | tags: tags
          }
        }

      {:error, message} ->
        {:error, message}
    end
  end

  @spec create_tags(Event.id()) :: {:ok, list()} | {:error, String.t()}
  defp create_tags(event_ids) do
    case to_hex(event_ids) do
      {:ok, hex_ids} -> {:ok, Enum.map(hex_ids, &["e", &1])}
      {:error, message} -> {:error, message}
    end
  end

  defp to_hex(event_ids) when is_list(event_ids) do
    conversion_results =
      event_ids
      |> Enum.map(&to_hex/1)

    case Enum.any?(conversion_results, &result_has_error?/1) do
      true ->
        {:error, "trying to delete, one of the element ids is in an invalid format"}

      false ->
        {:ok, Enum.map(conversion_results, fn {:ok, hex_id} -> hex_id end)}
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

  defp result_has_error?({:ok, _}), do: false
  defp result_has_error?({:error, _}), do: true
end
