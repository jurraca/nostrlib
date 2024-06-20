defmodule Nostrlib.Keys.PublicKey do
  @moduledoc """
  Public keys management functions
  """

  @type id :: String.t() | <<_::256>>

  alias Nostrlib.Utils
  alias Bitcoinex.Secp256k1.{PrivateKey, Point}

  @doc """
  Issues the public key corresponding to a given private key
  """
  @spec from_private_key(PrivateKey.t()) :: {:ok, String.t()} | {:error, String.t()}
  def from_private_key(%PrivateKey{} = private_key) do
    <<_b::size(8), pubkey::binary>> =
      private_key
      |> PrivateKey.to_point()
      |> Point.sec()

    {:ok, pubkey}
  end

  @spec from_private_key(<<_::256>>) :: {:ok, <<_::256>>}
  def from_private_key(bin) do
    {:ok, privkey} = bin |> :binary.decode_unsigned() |> PrivateKey.new()
    from_private_key(privkey)
  end

  def from_npub("npub" <> _data = npub), do: Utils.from_bech32(npub)
  def from_npub(not_an_npub), do: {:error, "Not an npub, got #{not_an_npub}"}

  @doc """
  Encodes a public key into the npub format
  """
  @spec to_npub(<<_::256>>) :: String.t()
  def to_npub(<<3::size(8), pubkey::binary>>), do: Utils.to_bech32(pubkey, "npub")
  def to_npub(<<_::256>> = pubkey), do: Utils.to_bech32(pubkey, "npub")

  @doc """
  Does its best to convert any public key format to binary, issues an error if it can't
  """
  @spec to_binary(<<_::256>> | String.t() | list(<<_::256>>)) ::
          {:ok, <<_::256>>} | {:error, String.t()}
  def to_binary("npub" <> _ = public_key) do
    case Bech32.decode(public_key) do
      {:ok, "npub", pubkey} -> {:ok, pubkey}
      {:error, message} -> {:error, message}
    end
  end

  def to_binary(<<_::256>> = public_key), do: {:ok, public_key}

  def to_binary(not_lowercase_npub) do
    case String.downcase(not_lowercase_npub) do
      "npub" <> _ = npub -> from_npub(npub)
      _ -> {:error, "#{not_lowercase_npub} is not a valid public key"}
    end
  end
end
