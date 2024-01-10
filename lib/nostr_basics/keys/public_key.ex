defmodule NostrBasics.Keys.PublicKey do
  @moduledoc """
  Public keys management functions
  """

  @type id :: String.t() | <<_::256>>

  alias NostrBasics.Utils
  alias NostrBasics.Keys.PrivateKey
  alias Bitcoinex.Secp256k1

  @doc """
  Issues the public key corresponding to a given private key
  """
  @spec from_private_key(<<_::256>>) ::
          {:ok, <<_::256>>} | {:error, String.t() | :signing_key_decoding_failed}
  def from_private_key(private_key) do
    case PrivateKey.to_binary(private_key) do
      {:ok, binary_private_key} ->
        pubkey =
          binary_private_key
          |> String.to_integer()
          |> Secp256k1.PrivateKey.new()
          |> Secp256k1.PrivateKey.to_point()
          |> Secp256k1.Point.serialize_public_key()

        {:ok, pubkey}

      {:error, message} ->
        {:error, message}
    end
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

  @doc """
  Converts a public key in the npub format into a binary public key that can be used with this lib
  """
  @spec from_npub(binary()) :: {:ok, binary()} | {:error, String.t()}
  def from_npub("npub" <> _ = bech32_pubkey) do
    case Bech32.decode(bech32_pubkey) do
      {:ok, "npub", pubkey} -> {:ok, pubkey}
      {:ok, _, _} -> {:error, "malformed bech32 public key"}
      {:error, message} -> {:error, message}
    end
  end

  @doc """
  Converts a public key in the npub format into a binary public key that can be used with this lib
  """
  @spec from_npub!(binary()) :: <<_::256>>
  def from_npub!("npub" <> _ = bech32_pubkey) do
    case from_npub(bech32_pubkey) do
      {:ok, pubkey} -> pubkey
      {:error, message} -> raise message
    end
  end

  @doc """
  Encodes a public key into the npub format
  """
  @spec to_npub(<<_::256>>) :: binary()
  def to_npub(<<_::256>> = public_key), do: Utils.to_bech32(public_key, "npub")

  @doc """
  Does its best to convert any public key format to binary, issues an error if it can't
  """
  @spec to_binary(<<_::256>> | String.t() | list(<<_::256>>)) ::
          {:ok, <<_::256>>} | {:error, String.t()}
  def to_binary(<<_::256>> = public_key), do: {:ok, public_key}
  def to_binary("npub" <> _ = public_key), do: from_npub(public_key)

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
