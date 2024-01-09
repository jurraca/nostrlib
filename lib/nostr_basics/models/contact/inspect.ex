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
