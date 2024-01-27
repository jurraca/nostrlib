defmodule Nostrlib.Event.Tags do
  @moduledoc """
  Parse and build tags according to NIP-01.

  This NIP defines 3 standard tags that can be used across all event kinds with the same meaning. They are as follows:

  The e tag, used to refer to an event: ["e", <32-bytes lowercase hex of the id of another event>, <recommended relay URL, optional>]
  The p tag, used to refer to another user: ["p", <32-bytes lowercase hex of a pubkey>, <recommended relay URL, optional>]
  The a tag, used to refer to a (maybe parameterized) replaceable event
      for a parameterized replaceable event: ["a", <kind integer>:<32-bytes lowercase hex of a pubkey>:<d tag value>, <recommended relay URL, optional>]
      for a non-parameterized replaceable event: ["a", <kind integer>:<32-bytes lowercase hex of a pubkey>:, <recommended relay URL, optional>]

  As a convention, all single-letter (only english alphabet letters: a-z, A-Z) key tags are expected to be indexed by relays, such that it is possible, for example, to query or subscribe to events that reference the event "5c83da77af1dec6d7289834998ad7aafbd9e2191396d75ec3cc27f5a77226f36" by using the {"#e": "5c83da77af1dec6d7289834998ad7aafbd9e2191396d75ec3cc27f5a77226f36"} filter.

  """

  defstruct [:name, :reference, :recommended_relay]

  def create(name, ref, marker) do
    create_tag(name, ref, marker)
  end

  def create_tag("e", ref, marker) do
    if Utils.valid_uri?(ref) and marker in ["reply", "root", "mention"] do
      ["e", ref, marker]
    else
      {:error, "Invalid tag URI or marker"}
    end
  end

  # event to reply to, or mention
  def type(["e" | rest]) do
    etag(rest)
  end

  defp etag([event_id, relay_url, marker]) do
    with true <- marker in ["reply", "root", "mention"],
         true <- Utils.valid_uri?(relay_url) do
      %{
        event_id: event_id,
        relay_url: relay_url,
        marker: marker
      }
    else
      {:error, reason} -> {:error, reason}
    end
  end

  # a p tag: public keys mentioned in event
  def type(["p" | rest]) do
    rest
    |> Enum.map(fn p -> Utils.valid_pubkey?(p) end)
    |> Enum.all?()
    |> ptag(rest)
  end

  defp ptag(true, tags), do: {:ok, %{reply_mentions: tags}}
  defp ptag(false, tags), do: {:error, "Invalid tags, got: #{tags}"}

  def type(["a" | rest]) do
  end

  def type(["i" | rest]) do
  end

  def type([name | rest]) do
  end
end
