defmodule NostrBasics.Utils do
  def to_hex(bin), do: Base.encode16(bin, case: :lower)

  def from_hex(bin), do: Base.decode16(bin, case: :lower)

  def json_decode(str) do
    case Jason.decode(str) do
      {:ok, event} ->
        {:ok, event}

      {:error, %Jason.DecodeError{position: position, token: token}} ->
        {:error, "error decoding JSON at position #{position}: #{token}"}

      {:error, _msg} ->
        {:error, "unknown JSON decode error"}
    end
  end

  def json_encode(map) do
    case Jason.encode(map) do
      {:ok, event} ->
        {:ok, event}

      {:error, %Jason.EncodeError{message: message}} ->
        {:error, "error encoding JSON: #{message}"}

      {:error, _msg} ->
        {:error, "unknown JSON encode error"}
    end
  end

  @spec sha256(String.t()) :: <<_::256>>
  def sha256(bin) when is_bitstring(bin) do
    :crypto.hash(:sha256, bin)
  end

  @doc """
  Converts an event binary id into a bech32 format
  """
  @spec to_bech32(<<_::256>> | String.t(), String.t()) :: String.t()
  def to_bech32(<<_::256>> = event_id, hrp), do: Bech32.encode(hrp, event_id)

  def to_bech32(hex_id, hrp) do
    hex_id
    |> from_hex()
    |> to_bech32(hrp)
  end

  @doc """
  Converts a bech32 event id into its binary format
  """
  @spec from_bech32(binary()) :: {:ok, binary(), binary()} | {:error, atom()}
  def from_bech32(bech32_event_id) do
    case Bech32.decode(bech32_event_id) do
      {:ok, hrp, event_id} -> {:ok, hrp, event_id}
      {:error, :no_seperator} -> {:error, "not a valid bech32 identifier"}
      {:error, message} -> {:error, message}
    end
  end

  @spec from_bech32!(binary()) :: <<_::256>>
  def from_bech32!(bech32_id) do
    case from_bech32(bech32_id) do
      {:ok, _hrp, event_id} -> event_id
      {:error, message} -> raise message
    end
  end
end
