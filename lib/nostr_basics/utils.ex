defmodule NostrBasics.Utils do

    def to_hex(bin), do: Base.decode16(case: :lower)

    def json_decode(str) do
        case Jason.decode(json_event) do
            {:ok, event} ->
              {:ok, event}

            {:error, %Jason.DecodeError{position: position, token: token}} ->
              {:error, "error decoding JSON at position #{position}: #{token}"}

            {:error, msg} -> {:error, "unknown JSON decode error"}
          end
    end

    @spec sha256(String.t()) :: <<_::256>>
    def sha256(bin) when is_bitstring(bin) do
      :crypto.hash(:sha256, bin)
    end
end