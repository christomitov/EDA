defmodule EDA.PaginatorTest do
  use ExUnit.Case, async: true

  alias EDA.Paginator

  describe "stream/1" do
    test "empty first page yields empty stream" do
      items = Paginator.stream(fetch: fn nil -> {:ok, []} end) |> Enum.to_list()
      assert items == []
    end

    test "single incomplete page halts after emitting items" do
      items =
        Paginator.stream(
          fetch: fn nil -> {:ok, [%{"id" => "1"}, %{"id" => "2"}]} end,
          per_page: 100
        )
        |> Enum.to_list()

      assert items == [%{"id" => "1"}, %{"id" => "2"}]
    end

    test "multi-page :before direction passes correct cursor" do
      cursors = :ets.new(:cursors, [:set, :public])
      :ets.insert(cursors, {:calls, []})

      items =
        Paginator.stream(
          fetch: fn cursor ->
            [{:calls, prev}] = :ets.lookup(cursors, :calls)
            :ets.insert(cursors, {:calls, prev ++ [cursor]})

            case cursor do
              nil -> {:ok, Enum.map(1..3, &%{"id" => to_string(100 - &1)})}
              "97" -> {:ok, [%{"id" => "50"}]}
            end
          end,
          cursor_key: "id",
          direction: :before,
          per_page: 3
        )
        |> Enum.to_list()

      assert length(items) == 4
      [{:calls, calls}] = :ets.lookup(cursors, :calls)
      assert calls == [nil, "97"]
      :ets.delete(cursors)
    end

    test "multi-page :after direction passes correct cursor" do
      items =
        Paginator.stream(
          fetch: fn
            nil -> {:ok, [%{"id" => "1"}, %{"id" => "2"}, %{"id" => "3"}]}
            "3" -> {:ok, [%{"id" => "4"}]}
          end,
          cursor_key: "id",
          direction: :after,
          per_page: 3
        )
        |> Enum.to_list()

      assert length(items) == 4
      assert List.last(items) == %{"id" => "4"}
    end

    test "nested cursor_key extracts from nested maps" do
      items =
        Paginator.stream(
          fetch: fn
            nil -> {:ok, [%{"user" => %{"id" => "a"}}, %{"user" => %{"id" => "b"}}]}
            "b" -> {:ok, []}
          end,
          cursor_key: ["user", "id"],
          per_page: 2
        )
        |> Enum.to_list()

      assert length(items) == 2
    end

    test "function cursor_key works with structs" do
      items =
        Paginator.stream(
          fetch: fn
            nil -> {:ok, [%{id: 10}, %{id: 20}]}
            20 -> {:ok, []}
          end,
          cursor_key: fn item -> item.id end,
          per_page: 2
        )
        |> Enum.to_list()

      assert items == [%{id: 10}, %{id: 20}]
    end

    test "error on first page yields empty stream" do
      items =
        Paginator.stream(fetch: fn nil -> {:error, :forbidden} end)
        |> Enum.to_list()

      assert items == []
    end

    test "error on second page yields only first page items" do
      items =
        Paginator.stream(
          fetch: fn
            nil -> {:ok, [%{"id" => "1"}, %{"id" => "2"}, %{"id" => "3"}]}
            "3" -> {:error, :server_error}
          end,
          cursor_key: "id",
          per_page: 3
        )
        |> Enum.to_list()

      assert length(items) == 3
    end

    test "Stream.take fetches only needed pages" do
      call_count = :counters.new(1, [])

      items =
        Paginator.stream(
          fetch: fn _ ->
            :counters.add(call_count, 1, 1)
            {:ok, Enum.map(1..100, &%{"id" => to_string(&1)})}
          end,
          cursor_key: "id",
          per_page: 100
        )
        |> Stream.take(50)
        |> Enum.to_list()

      assert length(items) == 50
      assert :counters.get(call_count, 1) == 1
    end

    test "initial_cursor is passed to first fetch" do
      received_cursor = :ets.new(:cursor, [:set, :public])

      Paginator.stream(
        fetch: fn cursor ->
          :ets.insert(received_cursor, {:first, cursor})
          {:ok, []}
        end,
        initial_cursor: "start_here"
      )
      |> Enum.to_list()

      [{:first, cursor}] = :ets.lookup(received_cursor, :first)
      assert cursor == "start_here"
      :ets.delete(received_cursor)
    end
  end
end
