defmodule EDA.API.Role do
  @moduledoc """
  REST API endpoints for Discord guild roles.

  All functions return `{:ok, result}` or `{:error, reason}`.
  """

  import EDA.HTTP.Client

  @doc "Gets roles for a guild."
  @spec list(String.t() | integer()) :: {:ok, [map()]} | {:error, term()}
  def list(guild_id) do
    EDA.HTTP.Client.get("/guilds/#{guild_id}/roles")
  end

  @doc "Creates a role in a guild."
  @spec create(String.t() | integer(), keyword() | map(), keyword()) ::
          {:ok, map()} | {:error, term()}
  def create(guild_id, params \\ [], opts \\ []) do
    body = if is_list(params), do: Map.new(params), else: params
    post("/guilds/#{guild_id}/roles", body, opts)
  end

  @doc "Modifies a guild role."
  @spec modify(String.t() | integer(), String.t() | integer(), map(), keyword()) ::
          {:ok, map()} | {:error, term()}
  def modify(guild_id, role_id, payload, opts \\ []) do
    patch("/guilds/#{guild_id}/roles/#{role_id}", payload, opts)
  end

  @doc "Deletes a guild role."
  @spec delete(String.t() | integer(), String.t() | integer(), keyword()) ::
          :ok | {:error, term()}
  def delete(guild_id, role_id, opts \\ []) do
    case EDA.HTTP.Client.delete("/guilds/#{guild_id}/roles/#{role_id}", opts) do
      {:ok, _} -> :ok
      error -> error
    end
  end

  @doc "Modifies guild role positions."
  @spec modify_positions(String.t() | integer(), [map()]) ::
          {:ok, [map()]} | {:error, term()}
  def modify_positions(guild_id, positions) do
    patch("/guilds/#{guild_id}/roles", positions)
  end
end
