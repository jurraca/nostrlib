defmodule Nostrlib.ModelsTest do
   use ExUnit.Case

   alias Nostrlib.{Event, Note}
   alias Nostrlib.Keys.{PrivateKey, PublicKey}

   setup do
    {:ok, privkey} = PrivateKey.new()
    {:ok, pubkey} = privkey |> PublicKey.from_private_key()
    hex_pubkey = Nostrlib.Utils.to_hex(pubkey)
    {:ok, privkey: privkey, pubkey: pubkey, hex_pubkey: hex_pubkey}
   end

   test "create note", %{privkey: privkey, pubkey: pubkey, hex_pubkey: hex_pubkey} do
       content = "testnote"
       note = Note.new(%{content: content})
       assert %Event{content: ^content, pubkey: ^hex_pubkey, sig: nil} = Note.to_event(note, hex_pubkey)
       assert {:ok, bin} = Note.to_event_serialized(note, privkey)
       assert is_binary(bin)
   end

end
