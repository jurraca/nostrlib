defmodule NostrBasics.Encoding.Nevent.Tokens do
  @moduledoc """
  Converts an encoded event id into tokens with specific meanings
  """

  @nevent "nevent"

  @doc """
  Extract tokens from a bech32 encoded string
  """
  @spec extract(binary()) :: {:ok, list()} | {:error, atom()}
  def extract(encoded) do
    case Bech32.decode(encoded) do
      {:ok, @nevent, data} ->
        extract_tokens([], data)

      {:error, message} ->
        {:error, message}
    end
  end

  @doc """
  ## Examples
      iex> [
      ...>   {0, <<0xfdcf4e971ebcda7dde5b6b2130492cf99fd58c3f8e9cc551498f0682aaa74430::256>>},
      ...>   {1,  "wss://relay.damus.io"},
      ...>   {2, <<0xdf173277182f3155d37b330211ba1de4a81500c02d195e964f91be774ec96708::256>>},
      ...>   {3, <<1::32>>}
      ...> ]
      ...> |> NostrBasics.Encoding.Nevent.Tokens.to_bech32
      "nevent1qqs0mn6wju0teknamedkkgfsfyk0n8743slca8x929yc7p5z42n5gvqpz3mhxue69uhhyetvv9ujuerpd46hxtnfdupzphchxfm3ste32hfhkvczzxapme9gz5qvqtget6tylyd7wa8vjecgqvzqqqqqqysdssmq"
  """
  @spec to_bech32(list()) :: binary()
  def to_bech32(tokens) do
    data =
      tokens
      |> Enum.reduce(<<>>, fn {type, value}, serialized ->
        length = byte_size(value)
        <<serialized::binary, type::8, length::8, value::binary-size(length)>>
      end)

    Bech32.encode("nevent", data)
  end

  defp extract_tokens(tokens, <<>>) do
    {
      :ok,
      tokens
      |> Enum.map(fn {type, data, _rest} -> {type, data} end)
      |> Enum.reverse()
    }
  end

  defp extract_tokens(tokens, <<type::8, length::8, rest::binary>>) do
    <<data::binary-size(length), rest::binary>> = rest

    extract_tokens([{type, data, rest} | tokens], rest)
  end

  defp extract_tokens(_, _), do: {:error, :malformed}
end
