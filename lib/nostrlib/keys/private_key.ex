defmodule Nostrlib.Keys.PrivateKey do
  @moduledoc """
  Private keys management functions. We use Bitcoinex's Secp functions.
  """

  @type id :: String.t() | <<_::256>>
  @type t :: %Bitcoinex.Secp256k1.PrivateKey{}

  alias Nostrlib.Utils
  alias Bitcoinex.Secp256k1.PrivateKey

  @doc """
  Creates a new private key
  """
  @spec new :: PrivateKey.t()
  def new do
    :crypto.strong_rand_bytes(32) |> from_binary()
  end

  def new(secret), do: from_binary(secret)

  @doc """
  Encodes a private key into the nsec format
  """
  @spec to_nsec(<<_::256>>) :: {:ok, binary()}
  def to_nsec(<<_::256>> = private_key), do: Utils.to_bech32(private_key, "nsec")

  def to_nsec(bin) when is_binary(bin) do
    {:error, "#{bin} should be a 256 bits private key"}
  end

  def to_nsec(%PrivateKey{} = privkey), do: privkey |> to_binary |> to_nsec

  @doc """
  Extracts a binary private key from the nsec format
  """
  @spec from_nsec(binary()) :: {:ok, <<_::256>>} | {:error, String.t()}
  def from_nsec("nsec" <> _ = nsec) do
    case Utils.from_bech32(nsec) do
      {:ok, "nsec", privkey_bin} ->
          from_binary(privkey_bin)

      {:ok, _, _} ->
        {:error, "malformed bech32 private key"}

      {:error, message} when is_atom(message) ->
        {:error, Atom.to_string(message)}
    end
  end

  def from_nsec(not_an_nsec) do
    {:error, "#{not_an_nsec} is not an nsec formatted address"}
  end

  @doc """
  Extracts a binary private key from the nsec format
  """
  @spec from_nsec!(binary()) :: <<_::256>>
  def from_nsec!("nsec" <> _ = nsec) do
    case from_nsec(nsec) do
      {:ok, private_key} -> private_key
      {:error, message} -> raise message
    end
  end

  def from_binary(bin) do
    bin
    |> :binary.decode_unsigned()
    |> PrivateKey.new()
  end

  @doc """
  Does its best to convert any private key format to binary, issues an error if it can't
  """
  @spec to_binary(PrivateKey.id()) :: {:ok, <<_::256>>} | {:error, String.t()}
  def to_binary(%PrivateKey{d: d}), do: :binary.encode_unsigned(d)
  def to_binary("nsec" <> _ = nsec), do: Utils.from_bech32(nsec)
  def to_binary(<<_::256>> = private_key), do: {:ok, private_key}

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
