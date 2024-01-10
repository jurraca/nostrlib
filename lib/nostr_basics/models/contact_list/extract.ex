defmodule NostrBasics.ContactList.Extract do
  @moduledoc """
  Convert a nostr event into a contact list
  """

  @contact_kind 3

  alias NostrBasics.Event
  alias NostrBasics.{Contact, ContactList}

  @doc """
  Converts an %Event{} into a %ContactList{}
  """
  @spec from_event(Event.t()) :: {:ok, ContactList.t()} | {:error, String.t()}
  def from_event(%{
        "kind" => @contact_kind,
        "pubkey" => pubkey,
        "content" => content,
        "tags" => tags
      }) do
    relays = extract_relays(content)
    contacts = Enum.map(tags, &parse_contact/1)

    {:ok,
     %ContactList{
       pubkey: pubkey,
       contacts: contacts,
       relays: relays
     }}
  end

  def from_event(_) do
    {:error, "not a contact list event"}
  end

  defp extract_relays(nil), do: []
  defp extract_relays(""), do: []

  defp extract_relays(relays_list) when is_binary(relays_list) do
    relays_list
    |> Jason.decode!()
    |> extract_relays()
  end

  defp extract_relays(relays_list) when is_map(relays_list) do
    relays_list
    |> Map.keys()
    |> Enum.map(fn url ->
      item = relays_list[url]

      %{
        url: url,
        read?: Map.get(item, "read"),
        write?: Map.get(item, "write")
      }
    end)
  end

  defp parse_contact(["p" | [hex_pubkey | [main_relay | [petname]]]]) do
    pubkey = Base.decode16(hex_pubkey, case: :lower)

    %Contact{pubkey: pubkey, main_relay: main_relay, petname: petname}
  end

  defp parse_contact(["p" | [hex_pubkey | [main_relay | []]]]) do
    pubkey = Base.decode16(hex_pubkey, case: :lower)

    %Contact{pubkey: pubkey, main_relay: main_relay}
  end

  defp parse_contact(["p" | [hex_pubkey | []]]) do
    pubkey = Base.decode16(hex_pubkey, case: :lower)

    %Contact{pubkey: pubkey}
  end

  defp parse_contact(data), do: %{unknown_content_type: data}
end
