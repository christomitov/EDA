defmodule EDA.Gateway.MemberChunker do
  @moduledoc """
  Orchestrates OP 8 (Request Guild Members) requests with nonce-based tracking.

  Supports fire-and-forget caching, synchronous awaiting, prefix search, and
  fetching by user IDs. Chunks are tracked by nonce and requests are cleaned up
  on timeout.
  """

  use GenServer

  require Logger

  @timeout_ms 15_000
  @cleanup_interval 5_000

  defmodule ChunkRequest do
    @moduledoc false
    defstruct [
      :nonce,
      :guild_id,
      :caller,
      :chunk_count,
      :started_at,
      chunks_received: 0,
      members: []
    ]
  end

  # ── Public API ──────────────────────────────────────────────────────

  @doc "Fire-and-forget: requests all members for a guild, caches automatically."
  @spec request(String.t() | integer(), keyword()) :: :ok
  def request(guild_id, opts \\ []) do
    GenServer.cast(__MODULE__, {:request, to_string(guild_id), nil, opts})
  end

  @doc "Requests all members and blocks until all chunks arrive."
  @spec await(String.t() | integer(), keyword()) :: {:ok, [map()]} | {:error, :timeout}
  def await(guild_id, opts \\ []) do
    GenServer.call(__MODULE__, {:request, to_string(guild_id), opts}, @timeout_ms + 5_000)
  end

  @doc "Searches members by username prefix (max 100 results)."
  @spec search(String.t() | integer(), String.t(), keyword()) ::
          {:ok, [map()]} | {:error, :timeout}
  def search(guild_id, query, opts \\ []) do
    opts = Keyword.merge([query: query, limit: min(Keyword.get(opts, :limit, 100), 100)], opts)
    GenServer.call(__MODULE__, {:request, to_string(guild_id), opts}, @timeout_ms + 5_000)
  end

  @doc "Fetches specific members by user IDs (max 100)."
  @spec fetch(String.t() | integer(), [String.t() | integer()], keyword()) ::
          {:ok, [map()]} | {:error, :timeout}
  def fetch(guild_id, user_ids, opts \\ []) do
    ids = user_ids |> Enum.take(100) |> Enum.map(&to_string/1)
    opts = Keyword.put(opts, :user_ids, ids)
    GenServer.call(__MODULE__, {:request, to_string(guild_id), opts}, @timeout_ms + 5_000)
  end

  @doc "Called by Events when a GUILD_MEMBERS_CHUNK arrives."
  @spec handle_chunk(map()) :: :ok
  def handle_chunk(data) do
    GenServer.cast(__MODULE__, {:chunk, data})
  end

  # ── GenServer ───────────────────────────────────────────────────────

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(_) do
    schedule_cleanup()
    {:ok, %{requests: %{}}}
  end

  @impl true
  def handle_call({:request, guild_id, opts}, from, state) do
    nonce = generate_nonce()
    send_op8(guild_id, nonce, opts)

    request = %ChunkRequest{
      nonce: nonce,
      guild_id: guild_id,
      caller: from,
      started_at: System.monotonic_time(:millisecond)
    }

    {:noreply, put_in(state, [:requests, nonce], request)}
  end

  @impl true
  def handle_cast({:request, guild_id, nil, opts}, state) do
    nonce = generate_nonce()
    send_op8(guild_id, nonce, opts)

    request = %ChunkRequest{
      nonce: nonce,
      guild_id: guild_id,
      caller: nil,
      started_at: System.monotonic_time(:millisecond)
    }

    {:noreply, put_in(state, [:requests, nonce], request)}
  end

  def handle_cast({:chunk, data}, state) do
    nonce = data["nonce"]

    case Map.fetch(state.requests, nonce) do
      {:ok, request} ->
        {:noreply, process_chunk(state, nonce, request, data)}

      :error ->
        {:noreply, state}
    end
  end

  @impl true
  def handle_info(:cleanup, state) do
    now = System.monotonic_time(:millisecond)

    {expired, remaining} =
      Map.split_with(state.requests, fn {_nonce, req} ->
        now - req.started_at > @timeout_ms
      end)

    for {_nonce, req} <- expired do
      if req.caller do
        GenServer.reply(req.caller, {:error, :timeout})
      end

      Logger.debug("MemberChunker: timed out request for guild #{req.guild_id}")
    end

    schedule_cleanup()
    {:noreply, %{state | requests: remaining}}
  end

  def handle_info(_msg, state), do: {:noreply, state}

  # ── Chunk processing ─────────────────────────────────────────────────

  defp process_chunk(state, nonce, request, data) do
    members = data["members"] || []
    chunk_index = data["chunk_index"] || 0
    chunk_count = data["chunk_count"] || 1

    cache_chunk(request.guild_id, members, data["presences"])

    updated = %{
      request
      | chunk_count: chunk_count,
        chunks_received: request.chunks_received + 1,
        members: request.members ++ members
    }

    complete_or_continue(state, nonce, updated, chunk_index, chunk_count)
  end

  defp cache_chunk(guild_id, members, presences) do
    for member <- members do
      if user = member["user"], do: EDA.Cache.User.create(user)
      EDA.Cache.Member.create(guild_id, member)
    end

    for presence <- presences || [] do
      EDA.Cache.Presence.upsert(guild_id, presence)
    end
  end

  defp complete_or_continue(state, nonce, request, chunk_index, chunk_count)
       when chunk_index == chunk_count - 1 do
    if request.caller, do: GenServer.reply(request.caller, {:ok, request.members})
    %{state | requests: Map.delete(state.requests, nonce)}
  end

  defp complete_or_continue(state, nonce, request, _chunk_index, _chunk_count) do
    put_in(state, [:requests, nonce], request)
  end

  # ── Internals ───────────────────────────────────────────────────────

  defp generate_nonce do
    :crypto.strong_rand_bytes(8) |> Base.hex_encode32(case: :lower, padding: false)
  end

  defp send_op8(guild_id, nonce, opts) do
    payload = build_op8_payload(guild_id, nonce, opts)

    try do
      shard_id = EDA.Gateway.ShardManager.shard_for_guild(guild_id)
      via = {:via, Registry, {EDA.Gateway.Registry, shard_id}}
      WebSockex.cast(via, {:request_guild_members, payload})
    rescue
      e ->
        Logger.warning(
          "MemberChunker: failed to send OP 8 for guild #{guild_id}: #{Exception.message(e)}"
        )
    end
  end

  defp build_op8_payload(guild_id, nonce, opts) do
    opts = opts || []
    user_ids = Keyword.get(opts, :user_ids)

    base = %{guild_id: guild_id, nonce: nonce}

    if user_ids do
      Map.put(base, :user_ids, user_ids)
    else
      query = Keyword.get(opts, :query, "")
      limit = Keyword.get(opts, :limit, 0)
      base |> Map.put(:query, query) |> Map.put(:limit, limit)
    end
  end

  defp schedule_cleanup do
    Process.send_after(self(), :cleanup, @cleanup_interval)
  end
end
