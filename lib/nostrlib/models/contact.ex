defmodule Nostrlib.Contact do
  @moduledoc """
  Represents a nostr contact that's being followed by someone
  """
  @derive Jason.Encoder
  defstruct [:pubkey, :main_relay, :petname]
end
