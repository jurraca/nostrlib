defmodule NostrBasics.Filter do
  @moduledoc """
  Details of a client subscription request to a relay
  """

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
    |> Map.put(:authors, decode_authors(encoded_request) )
  end

  @doc """
  Converts a structured Filter into a NIP-01 JSON REQ string
  """
  @spec to_query(Filter.t()) :: {:ok, String.t()} | {:error, String.t()}
  def to_query(filter) do
    since_timestamp = if(filter.since, do: DateTime.to_unix(filter.since))
    hex_authors = encode_authors(authors)

    filter
    |> Map.put(:timestamp, since_timestamp)
    |> Map.put(:authors, hex_authors)
    |> Jason.encode()
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
