defmodule NostrlibTest.Events do
    use ExUnit.Case

    alias Nostrlib.Event
    alias Nostrlib.Keys.{PublicKey, PrivateKey}

    setup do
        {:ok, privkey} = PrivateKey.create()
        {:ok, privkey: privkey}
    end

    test "create an event from a text note", %{privkey: privkey} do
        {:ok, hex_pubkey} = privkey |> PublicKey.from_private_key() |> Nostrlib.Utils.to_hex()
        %Event{} = event = Event.create(1, "testnote", hex_pubkey)
        assert event.content == "testnote"
        assert event.pubkey == hex_pubkey
        assert event.kind == 1
    end

    test "signs events correctly" do
    end

    test "validates an event's data and sig" do
    end

    test "returns error on bad sig for event" do
    end

    test "does the nostr encoding correctly" do
    end

    test "decode an event correctly" do
    end

    test "converts to nevent" do
    end
end
