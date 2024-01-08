defmodule NostrBasics.Contact do
  @moduledoc """
  Represents a nostr contact that's being followed by someone
  """

  defstruct [:pubkey, :main_relay, :petname]
end
