defmodule Nostrlib.ContactList do
  @moduledoc """
  Represents a nostr user's contact list and relays.
  """
  use Flint

  alias Nostrlib.{Contact, Event}

  @kind 3

  embedded_schema do
    embeds_many :contacts, Contact
  end

  def to_event(%__MODULE__{contacts: contacts}) do
     follows = Enum.map(contacts, &Contact.to_tag(&1))
     Event.new(%{tags: follows, content: "", kind: @kind})
  end

  @doc """
  Converts an %Event{} into a %ContactList{}
  """
  @spec from_event(Event.t()) :: ContactList.t()
  def from_event(%Event{tags: tags, kind: 3}) do
    contacts = Enum.map(tags, fn tag -> Contact.parse(tag) end)
    new(%{contacts: contacts})
  end

  def add(%{contacts: contacts} = contact_list, pubkey) do
    contact = %Contact{pubkey: pubkey}

    new_contacts = [contact | contacts]

    %{contact_list | contacts: new_contacts}
  end

  def remove(%{contacts: contacts} = contact_list, pubkey_to_remove) do
    new_contacts =
      contacts
      |> Enum.filter(fn %Contact{pubkey: contact_pubkey} ->
        pubkey_to_remove != contact_pubkey
      end)

    %{contact_list | contacts: new_contacts}
  end
end
