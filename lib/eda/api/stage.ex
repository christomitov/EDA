defmodule EDA.API.Stage do
  @moduledoc """
  REST API endpoints for Discord stage instances.

  All functions return `{:ok, result}` or `{:error, reason}`.
  """

  import EDA.HTTP.Client

  @doc """
  Creates a stage instance.

  ## Parameters (map)
  - `:channel_id` - The stage channel ID (required)
  - `:topic` - The topic of the stage instance (required, 1-120 chars)
  - `:privacy_level` - Privacy level (currently only 2 for GUILD_ONLY)
  - `:send_start_notification` - Notify @everyone that a stage instance has started
  - `:guild_scheduled_event_id` - Associated scheduled event ID
  """
  @spec create(map()) :: {:ok, map()} | {:error, term()}
  def create(params) do
    post("/stage-instances", params)
  end

  @doc "Gets a stage instance by channel ID."
  @spec get(String.t() | integer()) :: {:ok, map()} | {:error, term()}
  def get(channel_id) do
    EDA.HTTP.Client.get("/stage-instances/#{channel_id}")
  end

  @doc "Modifies a stage instance."
  @spec modify(String.t() | integer(), map()) :: {:ok, map()} | {:error, term()}
  def modify(channel_id, params) do
    patch("/stage-instances/#{channel_id}", params)
  end

  @doc "Deletes a stage instance by channel ID."
  @spec delete(String.t() | integer()) :: :ok | {:error, term()}
  def delete(channel_id) do
    case EDA.HTTP.Client.delete("/stage-instances/#{channel_id}") do
      {:ok, _} -> :ok
      error -> error
    end
  end
end
