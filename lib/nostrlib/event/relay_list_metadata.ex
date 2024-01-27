defmodule Nostrlib.Event.RelayListMetadata do
  @moduledoc """
  Parse and build Relay List Metadata events according to NIP-65
  """

  alias Nostrlib.Utils

  @kind 10002

  def create(tags) do
    case format_tags(tags, []) do
      {:ok, tag_list} ->
        %{
          kind: @kind,
          content: "",
          tags: tag_list
        }

      {:error, _} = err ->
        err
    end
  end

  def format_tags([], acc), do: {:ok, acc}

  def format_tags([["r", reference | rest] = tag | tags], acc) do
    with true <- Utils.valid_uri?(reference),
         true <- valid_marker?(rest) do
      format_tags(tags, [tag | acc])
    else
      false -> {:error, "Tag URL or marker is invalid."}
      _ -> {:error, "unknown error"}
    end
  end

  @doc """
  If you don't have tags, default to read/write.
  We make it explicit when creating an event.
  """
  def valid_marker?([]), do: true
  def valid_marker?([marker]), do: marker in ["read", "write"]
end
