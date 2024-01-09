defmodule NostrBasics.Utils do

    def to_hex(bin), do: Base.encode16(bin, case: :lower)

    def from_hex(bin), do: Base.decode16(bin, case: :lower)

    def json_decode(str) do
        case Jason.decode(str) do
            {:ok, event} ->
              {:ok, event}

            {:error, %Jason.DecodeError{position: position, token: token}} ->
              {:error, "error decoding JSON at position #{position}: #{token}"}

            {:error, _msg} -> {:error, "unknown JSON decode error"}
          end
    end

    def json_encode(map) do
      case Jason.encode(map) do
        {:ok, event} ->
          {:ok, event}

        {:error, %Jason.EncodeError{message: message}} ->
          {:error, "error encoding JSON: #{message}"}

        {:error, _msg} -> {:error, "unknown JSON encode error"}
      end
    end

    @spec sha256(String.t()) :: <<_::256>>
    def sha256(bin) when is_bitstring(bin) do
      :crypto.hash(:sha256, bin)
    end
end
