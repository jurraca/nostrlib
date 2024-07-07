defmodule NostrlibTest.Events do
  use ExUnit.Case

  alias Nostrlib.Event
  alias Nostrlib.Keys.{PublicKey, PrivateKey}

  setup do
    {:ok, privkey} = PrivateKey.new()
    {:ok, pubkey} = privkey |> PublicKey.from_private_key()
    hex_pubkey = Nostrlib.Utils.to_hex(pubkey)
    event = Event.create(1, "testnote", hex_pubkey)
    timestamp = 1718124828
    {:ok, privkey: privkey, pubkey: hex_pubkey, ts: timestamp, event: event}
  end

  test "create an event from a text note", %{event: event, pubkey: pubkey} do
    assert event.content == "testnote"
    assert event.pubkey == pubkey
    assert event.kind == 1
  end

  test "encodes an event correctly", %{event: event, ts: ts} do
    %{id: id} = %{event | created_at: ts} |> Event.add_id()
    assert id
  end

  test "signs events correctly", %{privkey: privkey, event: event} do
    assert {:ok, signed_event } = Event.sign(event, privkey) 
    assert Event.validate_event(signed_event)
  end

  test "returns error on bad sig for event", %{event: not_signed_event} do
    assert {:error, "signature field is empty"} = Event.validate_event(not_signed_event)
  end

  test "decodes an event correctly", %{event: event, privkey: privkey} do
    {:ok, %{sig: sig} = signed_event} = Event.sign(event, privkey)
    {:ok, json_event } = Event.encode(signed_event)
    assert {:ok, %Event{} = decoded_event} = Event.decode(json_event)
    assert %{event | sig: sig} == decoded_event 
  end

  test "returns an error when decoding an invalid event", %{event: event, privkey: privkey} do
    {:ok, signed_event} = Event.sign(event, privkey)
    {:ok, empty_sig} = Event.encode(event)
    {:ok, bad_sig} = Event.encode(%{event | sig: "longinvalidsignaturefieldstest12355"})
    {:ok, bad_id} = Event.encode(%{signed_event | id: "bad_id123"})
    assert {:error, _} = Event.decode(empty_sig)
    assert {:error, _} = Event.decode(bad_sig)
    assert {:error, _} = Event.decode(bad_id)
  end

  test "does the nostr encoding correctly" do
  end

  test "converts to nevent" do
  end
end
