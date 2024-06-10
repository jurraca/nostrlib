defmodule Nostrlib.Filter do
  @moduledoc """
  Creates Nostr REQ events, i.e. subscription filters.
  The main builder is the `Filter.new/1` function
  """

  alias Nostrlib.Utils

  @valid_keys [:since, :until, :limit, :ids, :authors, :kinds, :e, :p]
  
  @default_id_size 16
  # hours back for messages
  @default_since 36
  @metadata_kind 0
  @text_kind 1
  @recommended_servers_kind 2
  @contacts_kind 3
  @deletion_kind 5
  @repost_kind 6
  @reaction_kind 7

  @doc """
  Create a new filter from a Map, Keyword list, or by key and value (for single field filters).
  """
  def new(params) do
    case validate(params) do
      {:ok, filter} -> {:ok, filter}
      {:error, reason} -> {:error, reason}
    end
  end

  def new(key, value) do
     [{key, value}] |> validate()
  end

  @doc """
  Compose a list of filters together into a single filter.
  """
  def from_list([final]), do: final
  def from_list([head, second | tail]) do
     new = merge(head, second)
     from_list([new | tail])
  end

  @doc """
  Merge two filters, handling conflicts according to the key type.
  "since", "until", and "opts" are simply overidden by the latest value provided.
  """
  def merge(f1, f2) do
     Map.merge(f1, f2, fn k, v1, v2 -> 
         cond do
            k in [:ids, :authors, :kinds] -> v1 ++ v2
            k in [:since, :until, :opts] -> v2
            true -> v1 ++ v2 # for e,p tags 
         end
     end)
  end

  def create_sub_id do
     generate_random_id() |> String.to_atom()
  end
  
  def encode(sub_id, filter) when is_map(filter) do
    Jason.encode(["REQ", sub_id, filter])
  end

  def decode(json), do: Utils.json_decode(json, keys: :atoms)

  ### Filter builders ### 

  def profile(pubkey, opts \\ []), do: filter_by_authors([pubkey], [@metadata_kind], opts)

  def recommended_servers(pubkey, opts \\ []), do: filter_by_authors([pubkey], [@recommended_servers_kind], opts)

  def contacts(pubkey, opts \\ []), do: filter_by_authors([pubkey], [@contacts_kind], opts)

  def note_by_id(id, opts \\ []), do: filter_by_ids([id], [@text_kind], opts) 

  def notes_by_id(ids, opts \\ []) when is_list(ids), do: filter_by_ids([ids], [@text_kind], opts)

  def kinds(kinds, opts \\ []) when is_list(kinds), do: filter_by_kind(kinds, opts)

  def notes(pubkeys, opts \\ []) when is_list(pubkeys) do
    filter_by_authors(pubkeys, [@text_kind], opts)
  end

  def deletions(pubkeys, opts \\ []) when is_list(pubkeys) do
    filter_by_authors(pubkeys, [@deletion_kind], opts)
  end

  def reposts(pubkeys, opts \\ []) when is_list(pubkeys) do
    filter_by_authors(pubkeys, [@repost_kind], opts)
  end

  def reactions(pubkeys, opts \\ []) when is_list(pubkeys) do
    filter_by_authors(pubkeys, [@reaction_kind], opts)
  end

  def all(opts \\ []) do
    # got to specify kinds, or else, some relays won't return anything
    new(%{kinds: [1, 5, 6, 7, 9735], since: opts[:since], opts: opts[:limit]})
  end

  defp filter_by_kind(kinds, opts) do
    %{kinds: kinds} |> filter_from_params(opts)
  end

  defp filter_by_ids(ids, kinds, opts) do
    %{
      ids: ids,
      kinds: kinds 
    }
    |> filter_from_params(opts)
  end

  defp filter_by_authors(pubkeys, kinds, opts) do
    %{
      authors: pubkeys,
      kinds: kinds
    }
    |> filter_from_params(opts)
  end

  defp filter_from_params(params, opts) do
    params
    |> put_opts(opts)
    |> new()
  end

  defp put_opts(filter, []), do: filter
  defp put_opts(filter, opts) do
    Enum.reduce(opts, filter, fn {k, v}, filter ->
      if k in [:since, :until, :opts] do
        Map.put(filter, k, v)
      end
    end)
  end

  def validate(params) do
      filter = Enum.reduce(params, %{}, fn {k, v}, acc -> validate(k, v, acc) end)
      case :since in Map.keys(filter) do
          true -> {:ok, filter}
          false -> 
              filter = Map.put(filter, :since, @default_since)
              {:ok, filter}
      end
  end

  def validate(key, value, acc) when is_atom(key) do
    case key in @valid_keys do
        true -> Map.put(acc, key, value)
        false -> {:error, "Invalid key for filter, got: #{key}"}
    end
  end

  def since_hours(hours) when is_integer(hours) do
    (DateTime.to_unix(DateTime.utc_now()) - 3600 * hours) |> DateTime.from_unix!
  end

  @spec generate_random_id(integer()) :: binary()
  defp generate_random_id(size \\ @default_id_size) do
    :crypto.strong_rand_bytes(size) |> Utils.to_hex()
  end
end
