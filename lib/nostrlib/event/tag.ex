defmodule Nostrlib.Event.Tag do
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
  use Flint

  embedded_schema do
    field! :type, :string
    field! :value, :string
    field :third, :string
    field :fourth, :string
  end

  @markers ["reply", "root", "mention"]

  def new(key, value, opts \\ []) do
    cond do
    opts.marker -> new([key, value, opts.recommended_relay, opts.marker])
    opts.recommended_relay -> new([key, value, opts.recommended_relay])
    true -> new([key, value])
    end
  end

  def new([type, value]) do
    struct!(__MODULE__, %{type: type, value: value})
  end

  def new([type, value, third]) do
    struct!(__MODULE__, %{type: type, value: value, third: third})
  end

  def new([type, value, third, fourth]) do
    struct!(__MODULE__, %{type: type, value: value, third: third, fourth: fourth})
  end

  def parse(["t", tag]), do: new([:hashtag, tag])
  def parse(["e", event_id]), do: new([:event, event_id])
  def parse(["p", pubkey]), do: new([:pubkey, pubkey])
  def parse(["r", url]), do: new([:url, url])

  def parse(["e", event_id, recommended_relay_url]) do
    new([:event, event_id, recommended_relay_url])
  end

  def parse(["p", pubkey, recommended_relay_url]) do
    new([:pubkey, pubkey, recommended_relay_url])
  end

  def parse(["e", event_id, recommended_relay_url, marker | _pubkey]) do
    case marker in @markers do
      true -> new([:event, event_id, recommended_relay_url, marker])
      false -> {:error, "invalid marker for event tag, got #{marker}"}
    end
  end

  def parse([type, value | _rest]) do
    new(type, value)
  end

  def create_tag("e", ref, marker) do
    if marker in ["reply", "root", "mention"] do
      ["e", ref, marker]
    else
      {:error, "Invalid tag URI or marker"}
    end
  end
end
