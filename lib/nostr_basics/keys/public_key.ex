defmodule NostrBasics.Keys.PublicKey do
  @moduledoc """
  Public keys management functions
  """

  @type id :: String.t() | <<_::256>>

  alias NostrBasics.Utils
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

  @doc """
  Issues the public key corresponding to a given private key
  """
  @spec from_private_key!(<<_::256>>) :: <<_::256>>
  def from_private_key!(private_key) do
    case from_private_key(private_key) do
      {:ok, public_key} -> public_key
      {:error, :signing_key_decoding_failed} -> raise "signing key decoding failed"
      {:error, message} -> raise message
    end
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
  def to_binary(<<_::256>> = public_key), do: {:ok, public_key}

  def to_binary("npub" <> _ = public_key) do
    case Bech32.decode(public_key) do
      {:ok, "npub", pubkey} -> {:ok, pubkey}
      {:ok, _, _} -> {:error, "malformed bech32 public key"}
      {:error, message} -> {:error, message}
    end
  end

  def to_binary(public_keys) when is_list(public_keys) do
    public_keys
    |> Enum.reverse()
    |> Enum.reduce({:ok, []}, &reduce_to_binaries/2)
  end

  def to_binary(not_lowercase_npub) do
    case String.downcase(not_lowercase_npub) do
      "npub" <> _ = npub -> from_npub(npub)
      _ -> {:error, "#{not_lowercase_npub} is not a valid public key"}
    end
  end

  defp reduce_to_binaries(public_key, acc) do
    case acc do
      {:ok, binary_public_keys} ->
        case to_binary(public_key) do
          {:ok, binary_public_key} ->
            {:ok, [binary_public_key | binary_public_keys]}

          {:error, message} ->
            {:error, message}
        end

      {:error, message} ->
        {:error, message}
    end
  end
end
