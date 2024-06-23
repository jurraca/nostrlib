## Inspect implementations for structs / data models

defimpl Inspect, for: Nostrlib.Models.ContactList do
  alias Nostrlib.HexBinary
  alias Nostrlib.ContactList

  def inspect(%ContactList{} = contact_list, opts) do
    %{
      contact_list
      | pubkey: %HexBinary{data: contact_list.pubkey}
    }
    |> Inspect.Any.inspect(opts)
  end
end

defimpl Inspect, for: Nostrlib.Models.Contact do
  alias Nostrlib.{Contact, HexBinary}

  def inspect(%Contact{} = contact, opts) do
    %{
      contact
      | pubkey: %HexBinary{data: contact.pubkey}
    }
    |> Inspect.Any.inspect(opts)
  end
end
