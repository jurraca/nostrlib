defmodule NostrBasics.Note do
  @moduledoc """
  Note struct and manipulation functions
  """

  defstruct [:content]

  alias NostrBasics.Event
  alias NostrBasics.Keys.PublicKey

  @type t :: %__MODULE__{}
  @type id :: String.t() | <<_::256>>

  @note_kind 1

  @doc """
  Creates a new nostr note
  """
  @spec to_event(Note.t(), PublicKey.id()) :: {:ok, Event.t()} | {:error, String.t()}
  def to_event(note, pubkey), do: Event.create(@note_kind, note, pubkey)
end
