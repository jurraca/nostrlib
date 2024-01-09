## Inspect implementations for structs / data models

defimpl Inspect, for: NostrBasics.Event do
  alias NostrBasics.HexBinary

  def inspect(%NostrBasics.Event{} = event, opts) do
    %{
      event
      | pubkey: %HexBinary{data: event.pubkey},
        sig: %HexBinary{data: event.sig}
    }
    |> Inspect.Any.inspect(opts)
  end
end

defimpl Inspect, for: NostrBasics.Filter do
  alias NostrBasics.{Filter, HexBinary}

  def inspect(
        %Filter{ids: raw_ids, authors: raw_authors, e: raw_e_list, p: raw_p_list} = filter,
        opts
      ) do
    %{
      filter
      | ids: inspect_identifier_list(raw_ids),
        authors: inspect_identifier_list(raw_authors),
        e: inspect_identifier_list(raw_e_list),
        p: inspect_identifier_list(raw_p_list)
    }
    |> Inspect.Any.inspect(opts)
  end

  defp inspect_identifier_list(nil), do: []

  defp inspect_identifier_list(raw_identifiers) do
    raw_identifiers
    |> Enum.map(fn identifier -> %HexBinary{data: identifier} end)
  end
end

defimpl Inspect, for: NostrBasics.Models.ContactList do
  alias NostrBasics.HexBinary
  alias NostrBasics.ContactList

  def inspect(%ContactList{} = contact_list, opts) do
    %{
      contact_list
      | pubkey: %HexBinary{data: contact_list.pubkey}
    }
    |> Inspect.Any.inspect(opts)
  end
end

defimpl Inspect, for: NostrBasics.Models.Contact do
  alias NostrBasics.{Contact, HexBinary}

  def inspect(%Contact{} = contact, opts) do
    %{
      contact
      | pubkey: %HexBinary{data: contact.pubkey}
    }
    |> Inspect.Any.inspect(opts)
  end
end
