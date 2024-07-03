defmodule Nostrlib.Contact do
  @moduledoc """
  Represents a nostr identity.
  """
  use Flint

  embedded_schema do
    field! :pubkey, :string
    field :relay, :string
    field :nickname, :string
  end

  def new(pubkey, relay, opts \\ []) do
      new(%{pubkey: pubkey, relay: relay, nickname: opts.nickname})
  end

  def to_tag(%__MODULE__{} = tag) do
    ["p", tag.pubkey, tag.relay, tag.nickname]
    |> Enum.reject(&is_nil/1)
  end

  def parse(["p", pubkey]), do: new(pubkey, nil)
  def parse(["p", pubkey, relay]), do: new(pubkey, relay)
  def parse(["p", pubkey, relay, nickname]), do: new(pubkey, relay, nickname: nickname)
  def parse(_), do: nil
end
