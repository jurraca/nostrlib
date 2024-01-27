defmodule Nostrlib.Filter do
  @moduledoc """
  A Filter represents the data requested in a subscription. These will be encoded into REQ messages (see `Request` module).
  """
  @derive Jason.Encoder
  defstruct [
    :subscription_id,
    :since,
    :until,
    :limit,
    ids: [],
    authors: [],
    kinds: [],
    e: [],
    p: []
  ]

  alias __MODULE__

  @type t :: %__MODULE__{}

  @doc """
  Converts a NIP-01 JSON REQ string into a structured Filter
  """
  @spec from_req(String.t(), String.t()) :: {:ok, Filter.t()} | {:error, String.t()}
  def from_req(req, subscription_id) do
    case Jason.decode(req) do
      {:ok, encoded_request} ->
        {
          :ok,
          decode(encoded_request, subscription_id)
        }

      {:error, %Jason.DecodeError{position: position, token: token}} ->
        {:error, "error decoding JSON at position #{position}: #{token}"}
    end
  end

  @doc """
  Converts a NIP-01 JSON REQ string into a structured Filter
  """
  @spec from_req!(String.t(), String.t()) :: Filter.t()
  def from_req!(req, subscription_id) do
    case from_req(req, subscription_id) do
      {:ok, filter} -> filter
      {:error, message} -> raise message
    end
  end

  @doc """
  Converts a JSON decoded encoded filter into a %Filter{}
  """
  def decode(encoded_request, subscription_id) do
    atom_map = Enum.map(encoded_request, fn {k, v} -> {String.to_atom(k), v} end)

    %Filter{}
    |> Map.merge(atom_map)
    |> Map.put(:subscription_id, subscription_id)
    |> Map.put(:authors, decode_authors(encoded_request))
  end

  defp decode_authors(%{"authors" => nil}), do: []

  defp decode_authors(%{"authors" => authors}) do
    Enum.map(authors, &Base.decode16!(&1, case: :lower))
  end

  defp encode_authors(%{"authors" => nil}), do: []

  defp encode_authors(%{"authors" => authors}) do
    Enum.map(authors, &Base.encode16(&1, case: :lower))
  end
end
