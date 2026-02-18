defmodule EDA.Paginator do
  @moduledoc """
  Generic lazy pagination helper for Discord API endpoints.

  Builds a `Stream.resource/3` that fetches pages on demand, yielding items
  one at a time with O(page_size) memory. The stream halts automatically when
  Discord returns an empty or incomplete page, or when an error occurs.

  ## Example

      EDA.Paginator.stream(
        fetch: fn cursor ->
          EDA.API.Ban.list(guild_id, limit: 1000, after: cursor)
        end,
        cursor_key: ["user", "id"],
        direction: :after,
        per_page: 1000
      )
      |> Stream.take(50)
      |> Enum.to_list()

  ## Options

  - `:fetch` (required) — `(cursor | nil -> {:ok, [item]} | {:error, term()})`.
    Receives `nil` on the first call, then the extracted cursor for subsequent pages.
  - `:cursor_key` — How to extract the cursor from each item. Accepts:
    - a string key (e.g. `"id"`) — uses `item["id"]`
    - a list of string keys (e.g. `["user", "id"]`) — uses `get_in/2`
    - a function `(item -> cursor)` — arbitrary extraction
    Defaults to `"id"`.
  - `:direction` — `:before` or `:after`. Defaults to `:before`.
  - `:per_page` — Page size, used to detect incomplete (final) pages. Defaults to `100`.
  - `:initial_cursor` — Starting cursor value. Defaults to `nil`.
  """

  @doc """
  Returns a lazy `Stream` that paginates through a Discord API endpoint.

  See module documentation for the full list of options.
  """
  @spec stream(keyword()) :: Enumerable.t()
  def stream(opts) do
    fetch = Keyword.fetch!(opts, :fetch)
    cursor_key = Keyword.get(opts, :cursor_key, "id")
    per_page = Keyword.get(opts, :per_page, 100)
    initial_cursor = Keyword.get(opts, :initial_cursor)

    Stream.resource(
      fn -> initial_cursor end,
      fn
        :halt -> {:halt, :done}
        cursor -> fetch_page(fetch, cursor, cursor_key, per_page)
      end,
      fn _ -> :ok end
    )
  end

  defp fetch_page(fetch, cursor, cursor_key, per_page) do
    case fetch.(cursor) do
      {:ok, []} ->
        {:halt, :done}

      {:ok, items} ->
        next =
          if length(items) < per_page,
            do: :halt,
            else: extract_cursor(List.last(items), cursor_key)

        {items, next}

      {:error, _} ->
        {:halt, :done}
    end
  end

  defp extract_cursor(item, key) when is_binary(key), do: item[key]
  defp extract_cursor(item, keys) when is_list(keys), do: get_in(item, keys)
  defp extract_cursor(item, fun) when is_function(fun, 1), do: fun.(item)
end
