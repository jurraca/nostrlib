defmodule Nostrlib.FilterTest do
  use ExUnit.Case

  alias Nostrlib.Filter

  describe "Create a filter with valid keys" do
    setup [:filter]

    test "success", %{filter: filter} do
      for key <- Map.keys(filter) do
        value = filter[key]
        assert {:ok, f1} = Filter.new([{key, value}])
        assert {:ok, f2} = Filter.new(key, value)
        assert f1 == f2
      end
    end

    test "can create a subscription id for a filter" do
      assert is_atom(Filter.create_sub_id())
    end

    test "can encode a sub id and filter into a REQ message", %{filter: filter} do
      filter = Map.take(filter, [:authors, :since])
      sub_id = Filter.create_sub_id()
      assert {:ok, request} = Filter.encode(sub_id, filter)
      assert is_binary(request)
      assert ["REQ", sub, _] = Jason.decode!(request)
      assert sub == Atom.to_string(sub_id)
    end

    test "compose filters together correctly", %{filter: filter} do
      f1 = Map.take(filter, [:authors, :since])
      f2 = Map.take(filter, [:kinds, :ids])
      {:ok, %{filters: [f1, f2]}}

      assert %{authors: f1.authors, since: f1.since, kinds: f2.kinds, ids: f2.ids} ==
               Filter.merge(f1, f2)

      f3 = %{authors: ["anotherpubkeydifferent"]}
      %{authors: final} = Filter.merge(f1, f2) |> Filter.merge(f3)
      assert f1.authors ++ f3.authors == final
    end
  end

  defp filter(context) do
    fields = %{
      ids: ["id1", "id2"],
      authors: ["apubkeytofollow"],
      kinds: [1, 935],
      since: DateTime.utc_now() |> DateTime.to_unix(),
      until: nil,
      limit: 10
    }

    Map.put(context, :filter, fields)
  end
end
