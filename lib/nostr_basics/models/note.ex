defmodule NostrBasics.Note do
  @moduledoc """
  Note struct and manipulation functions
  """

  defstruct [:content]

  alias NostrBasics.Event
  alias NostrBasics.Keys.PublicKey

  @type t :: %Note{}
  @type id :: String.t() | <<_::256>>

  @doc """
  Creates a new nostr note
  """
  @spec to_event(Note.t(), PublicKey.id()) :: {:ok, Event.t()} | {:error, String.t()}
  def to_event(note, pubkey) do
    Event.create(@note_kind, content, note_pubkey)
  end

  @doc """
  Creates a bech32 id for a note
  """
  @spec id_to_bech32(binary()) :: binary()
  def id_to_bech32(<<_::256>> = id), do: Bech32.encode("note", id)
  def id_to_bech32(id), do: Bech32.encode("note", Binary.from_hex(id))
end
