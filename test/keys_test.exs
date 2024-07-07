defmodule NostrlibTest.Keys do
  use ExUnit.Case

  alias Bitcoinex.Secp256k1.PrivateKey, as: Secp
  alias Nostrlib.Keys.PrivateKey
  alias Nostrlib.Keys.PublicKey

  setup do
    {:ok, privkey} = PrivateKey.new()
    {:ok, pubkey} = PublicKey.from_private_key(privkey)
    {:ok, privkey: privkey, pubkey: pubkey}
  end

  test "creates a privkey", %{privkey: privkey} do
    assert {:ok, _} = Secp.validate(privkey)
  end

  test "converts to/from nsec", %{privkey: privkey} do
    nsec = privkey |> PrivateKey.to_binary() |> PrivateKey.to_nsec()
    {:ok, privkey2} = PrivateKey.from_nsec(nsec)
    assert "nsec" <> _bin = nsec
    assert privkey == privkey2
  end

  test "throws error when converting a malformed private key to nsec" do
    assert {:error, _msg} = PrivateKey.to_nsec("too_short")
  end

  test "throws error when converting from a malformed nsec" do
    nsec_no_prefix = "not_an_nsec"

    assert {:error, msg} = PrivateKey.from_nsec(nsec_no_prefix)
    assert msg =~ "not an nsec"
  end

  test "from binary and back" do
  end

  test "converts to/from npub", %{pubkey: pubkey} do
    assert "npub" <> data = PublicKey.to_npub(pubkey) 
    assert {:ok, "npub", pubkey} == PublicKey.from_npub("npub" <> data)
  end

  test "returns error on invalid npub" do
     assert {:error, _msg} = PublicKey.from_npub("notannpub") 
  end
end
