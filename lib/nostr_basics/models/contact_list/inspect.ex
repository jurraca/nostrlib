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
