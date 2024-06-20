defmodule Nostrlib.Utils do
  @moduledoc """
  Utility functions: hex encoding/decoding, json encoding/decoding, bech32...
  """

  def to_hex(bin) when is_binary(bin), do: Base.encode16(bin, case: :lower)

  def from_hex(bin) when is_binary(bin), do: Base.decode16!(bin, case: :lower)

  def json_decode(str, opts \\ []) do
    case Jason.decode(str, opts) do
      {:ok, event} ->
        {:ok, event}

      {:error, %Jason.DecodeError{position: position, token: token}} ->
        {:error, "error decoding JSON at position #{position}: #{token}"}
    end
  end

  def json_encode(data) do
    case Jason.encode(data) do
      {:ok, event} ->
        {:ok, event}

      {:error, %Jason.EncodeError{message: message}} ->
        {:error, "error encoding JSON: #{message}"}

      {:error, _msg} ->
        {:error, "unknown JSON encode error"}
    end
  end

  @spec sha256(String.t()) :: <<_::256>>
  def sha256(bin) when is_binary(bin), do: :crypto.hash(:sha256, bin)

  @doc """
  Converts a binary into a bech32 format
  """
  def to_bech32(data, hrp), do: Bech32.encode(hrp, data)

  def to_bech32_from_hex(hex_id, hrp) do
    hex_id
    |> from_hex()
    |> to_bech32(hrp)
  end

  @doc """
  Converts a bech32 event id into its binary format
  """
  @spec from_bech32(binary()) :: {:ok, binary(), binary()} | {:error, atom()}
  def from_bech32(str) do
    case Bech32.decode(str) do
      {:ok, hrp, data} -> {:ok, hrp, data}
      {:error, message} -> {:error, message}
    end
  end

  def valid_uri?(uri) do
    case URI.parse(uri) do
      %URI{
        scheme: "ws",
        host: host
      } ->
        if(host, do: true, else: false)

      %URI{
        scheme: "wss",
        host: host
      } ->
        if(host, do: true, else: false)

      _ ->
        false
    end
  end

  def valid_pubkey?(pubkey) do
    case Base.decode16(pubkey, case: :lower) do
      {:ok, _} -> true
      err -> err
    end
  end
end
