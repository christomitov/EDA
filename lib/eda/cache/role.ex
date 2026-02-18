defmodule EDA.Cache.Role do
  @moduledoc """
  ETS-based cache for Discord roles.

  Uses composite keys `{guild_id, role_id}` for O(guild_size) lookups
  via `for_guild/1` instead of full table scans. A reverse index table
  maps `role_id` to `guild_id` for efficient single-role lookups.
  """

  use GenServer

  @table :eda_roles
  @index :eda_roles_index
  @cache_name :roles

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Gets a role by ID.
  """
  @spec get(String.t() | integer()) :: map() | nil
  def get(role_id) do
    role_id = to_string(role_id)

    case :ets.lookup(@index, role_id) do
      [{_, guild_id}] ->
        case :ets.lookup(@table, {guild_id, role_id}) do
          [{_, role}] ->
            :telemetry.execute([:eda, :cache, :hit], %{count: 1}, %{cache: @cache_name})
            role

          [] ->
            :telemetry.execute([:eda, :cache, :miss], %{count: 1}, %{cache: @cache_name})
            nil
        end

      [] ->
        :telemetry.execute([:eda, :cache, :miss], %{count: 1}, %{cache: @cache_name})
        nil
    end
  end

  @doc """
  Gets all roles for a guild. O(guild_size) via match_object.
  """
  @spec for_guild(String.t() | integer()) :: [map()]
  def for_guild(guild_id) do
    guild_id = to_string(guild_id)

    :ets.match_object(@table, {{guild_id, :_}, :_})
    |> Enum.map(fn {_, role} -> role end)
  end

  @doc """
  Gets all cached roles.
  """
  @spec all() :: [map()]
  def all do
    :ets.tab2list(@table)
    |> Enum.map(fn {_, role} -> role end)
  end

  @doc """
  Creates or replaces a role in the cache.
  """
  @spec create(String.t(), map()) :: map()
  def create(guild_id, role) do
    guild_id = to_string(guild_id)
    role_id = to_string(role["id"])
    key = {guild_id, role_id}
    role_with_guild = Map.put(role, "guild_id", guild_id)

    case EDA.Cache.Policy.check(
           EDA.Cache.Config.policy(@cache_name),
           :role,
           key,
           role_with_guild
         ) do
      :cache ->
        :ets.insert(@table, {key, role_with_guild})
        :ets.insert(@index, {role_id, guild_id})
        EDA.Cache.Evictor.touch(@table, key)
        :telemetry.execute([:eda, :cache, :write], %{count: 1}, %{cache: @cache_name})
        role_with_guild

      :skip ->
        :telemetry.execute([:eda, :cache, :skip], %{count: 1}, %{cache: @cache_name})
        role_with_guild
    end
  end

  @doc """
  Updates a role in the cache.
  """
  @spec update(String.t(), map()) :: map() | nil
  def update(role_id, updates) do
    role_id = to_string(role_id)

    case get(role_id) do
      nil ->
        nil

      existing ->
        updated = Map.merge(existing, updates)
        guild_id = updated["guild_id"]
        :ets.insert(@table, {{guild_id, role_id}, updated})
        updated
    end
  end

  @doc """
  Deletes a role from the cache.
  """
  @spec delete(String.t() | integer()) :: :ok
  def delete(role_id) do
    role_id = to_string(role_id)

    case :ets.lookup(@index, role_id) do
      [{_, guild_id}] ->
        key = {guild_id, role_id}
        :ets.delete(@table, key)
        :ets.delete(@index, role_id)
        EDA.Cache.Evictor.remove(@table, key)

      [] ->
        :ok
    end

    :ok
  end

  @doc """
  Removes all roles for a guild.
  """
  @spec delete_guild(String.t() | integer()) :: :ok
  def delete_guild(guild_id) do
    guild_id = to_string(guild_id)

    roles = :ets.match(@table, {{guild_id, :"$1"}, :_})

    for [role_id] <- roles do
      :ets.delete(@index, role_id)
    end

    :ets.match_delete(@table, {{guild_id, :_}, :_})
    :ok
  end

  @doc """
  Returns the total number of cached roles.
  """
  @spec count() :: non_neg_integer()
  def count do
    :ets.info(@table, :size)
  end

  @impl true
  def init(_opts) do
    :ets.new(@table, [:set, :public, :named_table, read_concurrency: true])
    :ets.new(@index, [:set, :public, :named_table, read_concurrency: true])
    {:ok, %{}}
  end
end
