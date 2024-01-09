defmodule NostrBasics.Keys.PrivateKey do
  @moduledoc """
  Private keys management functions
  """

  @type id :: String.t() | <<_::256>>

  alias NostrBasics.Utils
  alias NostrBasics.Keys.PrivateKey
  alias Bitcoinex.Secp256k1.PrivateKey

  @doc """
  Creates a new private key
  """
  @spec create() :: %PrivateKey{d: integer()}
  def create do
    :crypto.strong_rand_bytes(32)
    |> :binary.decode_unsigned()
    |> PrivateKey.new()
  end

  @doc """
  Extracts a binary private key from the nsec format
  """
  @spec from_nsec(binary()) :: {:ok, <<_::256>>} | {:error, String.t()}
  def from_nsec("nsec" <> _ = bech32_private_key) do
    case Bech32.decode(bech32_private_key) do
      {:ok, "nsec", private_key} ->
        if bit_size(private_key) == 256 do
          {:ok, private_key}
        else
          {:error, "private key is shorter than 256 bits"}
        end

      {:ok, _, _} ->
        {:error, "malformed bech32 private key"}

      {:error, message} when is_atom(message) ->
        {:error, Atom.to_string(message)}
    end
  end

  def from_nsec(badly_formatted_address) do
    {:error, "#{badly_formatted_address} is not an nsec formatted address"}
  end

  @doc """
  Extracts a binary private key from the nsec format
  """
  @spec from_nsec!(binary()) :: <<_::256>>
  def from_nsec!("nsec" <> _ = bech32_private_key) do
    case from_nsec(bech32_private_key) do
      {:ok, private_key} -> private_key
      {:error, message} -> raise message
    end
  end

  @doc """
  Encodes a private key into the nsec format
  """
  @spec to_nsec(<<_::256>>) :: binary()
  def to_nsec(<<_::256>> = private_key) do
    Utils.to_bech32(private_key, "nsec")
  end

  def to_nsec(not_a_256_bits_private_key) do
    {:error, "#{not_a_256_bits_private_key} should be a 256 bits private key"}
  end

  @doc """
  Does its best to convert any private key format to binary, issues an error if it can't
  """
  @spec to_binary(PrivateKey.id()) :: {:ok, <<_::256>>} | {:error, String.t()}
  def to_binary(<<_::256>> = private_key), do: {:ok, private_key}
  def to_binary("nsec" <> _ = private_key), do: from_nsec(private_key)

  def to_binary(not_lowercase_nsec) do
    case String.downcase(not_lowercase_nsec) do
      "nsec" <> _ = nsec -> from_nsec(nsec)
      _ -> {:error, "#{not_lowercase_nsec} is not a valid private key"}
    end
  end

  @doc """
  Does its best to convert any private key format to binary, raises an error if it can't
  """
  @spec to_binary!(PrivateKey.id()) :: <<_::256>>
  def to_binary!(private_key) do
    case to_binary(private_key) do
      {:ok, binary_private_key} -> binary_private_key
      {:error, message} -> raise message
    end
  end
end
