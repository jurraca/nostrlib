defmodule Nostrlib.Event.Id do
  @moduledoc """
  Event id conversion functions
  """

  alias Nostrlib.Utils

  @doc """
  Does its best to convert any event id format to binary, issues an error if it can't
  """
  @spec to_binary(<<_::256>> | String.t() | list()) ::
          {:ok, <<_::256>>}
          | {:ok, <<_::512>>}
          | {:ok, list(<<_::256>>)}
          | {:error, String.t()}
  def to_binary(<<_::256>> = event_id), do: {:ok, event_id}
  def to_binary(<<_::512>> = event_id), do: {:ok, Utils.from_hex(event_id)}

  def to_binary(event_id) when is_binary(event_id) do
    case Utils.from_bech32(event_id) do
      {:ok, _, binary} -> {:ok, binary}
      {:error, message} -> {:error, message}
    end
  end

  def to_binary(event_ids) when is_list(event_ids) do
    event_ids
    |> Enum.reverse()
    |> Enum.reduce({:ok, []}, &reduce_to_binaries/2)
  end

  def to_binary(not_lowercase_bech32_event_id) do
    not_lowercase_bech32_event_id
    |> String.downcase()
    |> Utils.from_bech32()
  end

  @spec reduce_to_binaries(String.t(), {:ok, list()} | {:error, String.t()}) ::
          {:ok, list()} | {:error, String.t()}
  defp reduce_to_binaries(event_id, acc) do
    case acc do
      {:ok, binary_event_ids} ->
        case to_binary(event_id) do
          {:ok, binary_event_id} ->
            {:ok, [binary_event_id | binary_event_ids]}

          {:error, message} ->
            {:error, message}
        end

      {:error, message} ->
        {:error, message}
    end
  end
end
