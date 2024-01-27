defmodule Nostrlib.Request do
  @moduledoc """
  Creates Nostr REQ events, i.e. subscription filters.
  The main builder is the `Request.new/1` function, which returns a tuple `{subscription_id, encoded_request}` for the client to send to relays, and subscribe to incoming events.
  Request creation will either be correct or return an error.
  """

  alias Nostrlib.{Filter, Utils}

  @default_id_size 16
  # hours back for messages
  @default_since 36

  @metadata_kind 0
  @text_kind 1
  @recommended_servers_kind 2
  @contacts_kind 3
  @encrypted_direct_message_kind 4
  @deletion_kind 5
  @repost_kind 6
  @reaction_kind 7

  def profile(pubkey) do
    get_by_authors([pubkey], [@metadata_kind], nil)
  end

  def recommended_servers(pubkey) do
    get_by_authors([pubkey], [@recommended_servers_kind], nil)
  end

  def contacts(pubkey, limit \\ 100) do
    get_by_authors([pubkey], [@contacts_kind], limit)
  end

  def note(id) do
    get_by_ids([id], @text_kind)
  end

  # fix and use Nostrlib.to_query/1
  def all(limit \\ 10) do
    # got to specify kinds, or else, some relays won't return anything
    new(%Filter{kinds: [1, 5, 6, 7, 9735], since: since(@default_since), limit: limit})
  end

  def kinds(kinds, limit \\ 10) when is_list(kinds) do
    new(%Filter{kinds: kinds, since: since(@default_since), limit: limit})
  end

  def notes(pubkeys, limit \\ 10) when is_list(pubkeys) do
    get_by_authors(pubkeys, [@text_kind], limit)
  end

  def deletions(pubkeys, limit \\ 10) when is_list(pubkeys) do
    get_by_authors(pubkeys, [@deletion_kind], limit)
  end

  def reposts(pubkeys, limit \\ 10) when is_list(pubkeys) do
    get_by_authors(pubkeys, [@repost_kind], limit)
  end

  def reactions(pubkeys, limit \\ 10) when is_list(pubkeys) do
    get_by_authors(pubkeys, [@reaction_kind], limit)
  end

  defp get_by_authors(pubkeys, kinds, limit) do
    pubkeys
    |> filter_by_authors(kinds, limit)
    |> new()
  end

  defp get_by_kind(kind, pubkeys, limit) do
    kind
    |> filter_by_kind(pubkeys, limit)
    |> new()
  end

  defp get_by_ids(ids, kind) do
    ids
    |> filter_by_ids(kind, 1)
    |> new()
  end

  defp filter_by_kind(kind, pubkeys, limit) do
    %Filter{
      kinds: [kind],
      p: pubkeys,
      limit: limit
    }
  end

  defp filter_by_ids(ids, kind, limit) do
    %Filter{
      ids: ids,
      kinds: [kind],
      limit: limit
    }
  end

  defp filter_by_authors(pubkeys, kinds, limit) when is_integer(limit) do
    %Filter{
      authors: pubkeys,
      kinds: kinds,
      since: since(@default_since),
      limit: limit
    }
  end

  defp filter_by_authors(pubkeys, kinds, _) do
    %Filter{
      authors: pubkeys,
      kinds: kinds
    }
  end

  @doc """
  For a given Filter struct, encode a request and a request/subscription ID
  """
  def new(filter) do
    filter = cast_to_struct(filter)
    sub_id = generate_random_id() |> String.to_atom()
    {filter, sub_id}
  end

  def format_request(%Filter{} = filter, sub_id) do
    case validate_filter(filter) do
      {:ok, _} -> Jason.encode(["REQ", sub_id, filter])
      {:error, _} = err -> err
    end
  end

  def format_request(id, filter) when is_binary(filter) do
    dec = Jason.decode!(filter)
    Jason.encode(["REQ", id, dec])
  end

  @doc """
  Take an Ecto struct and cast it to a Nostrlib.Filter struct.
  Allows the user to create their own data structures while validating Filter.
  """
  def cast_to_struct(filter) do
    params = filter |> Map.from_struct() |> Map.to_list()
    struct(%Filter{}, params)
  end

  @spec generate_random_id(integer()) :: binary()
  defp generate_random_id(size \\ @default_id_size) do
    :crypto.strong_rand_bytes(size) |> Utils.to_hex()
  end

  defp since(hours) when is_integer(hours) do
    DateTime.from_unix!(DateTime.to_unix(DateTime.utc_now()) - 3600 * hours)
  end

  # a filter should always have kinds, since, and limit
  # validate values for all three, if all true, serialize
  defp validate_filter(%{kinds: k, since: _s, limit: l} = filter) do
    with true <- Enum.count(k) > 0,
         true <- is_integer(l) do
      {:ok, filter}
    else
      {:error, reason} -> {:error, reason}
      _ -> {:error, "Your filter must specify kinds, since and limit parameters."}
    end
  end

  defp validate_filter(filter) do
    keys = filter |> Map.keys() |> Enum.join(", ")
    {:error, "Filter missing required keys: existing keys are #{keys}"}
  end

  defp hexify(keys) when is_list(keys) do
    Enum.map(keys, &Utils.to_hex(&1))
  end
end
