defmodule NostrBasics.ContactList do
  @moduledoc """
  Represents a nostr user's contact list and relays.
  """
  @derive Jason.Encoder
  defstruct [:pubkey, :contacts, :relays]

  alias __MODULE__
  alias NostrBasics.{Contact, Event, Utils}

  @type t :: %__MODULE__{}

  @contact_kind 3
  @empty_petname ""

  @doc """
  Converts an %Event{} into a %ContactList{}
  """
  @spec from_event(Event.t()) :: {:ok, ContactList.t()} | {:error, String.t()}
  def from_event(event), do: ContactList.Extract.from_event(event)

  @doc """
  Converts an %ContactList{} into an %Event{}
  """
  def get_content_and_tags(%ContactList{contacts: contacts, relays: relays}) do
    content = content_from_relays(relays)
    tags = tags_from_contacts(contacts)

    {:ok, content, tags}
  end

  defp tags_from_contacts(contacts) do
    contacts
    |> Enum.map(fn %Contact{pubkey: pubkey} ->
      ["p", Utils.to_hex(pubkey), @empty_petname]
    end)
  end

  defp content_from_relays(nil), do: ""

  defp content_from_relays(relays) do
    for %{url: url, read?: read?, write?: write?} <- relays do
      {url, %{read: read?, write: write?}}
    end
    |> Map.new()
    |> Jason.encode!()
  end

  def add(%ContactList{contacts: contacts} = contact_list, pubkey) do
    contact = %Contact{pubkey: pubkey}

    new_contacts = [contact | contacts]

    %{contact_list | contacts: new_contacts}
  end

  def remove(%ContactList{contacts: contacts} = contact_list, pubkey_to_remove) do
    new_contacts =
      contacts
      |> Enum.filter(fn %Contact{pubkey: contact_pubkey} ->
        pubkey_to_remove != contact_pubkey
      end)

    %{contact_list | contacts: new_contacts}
  end
end
