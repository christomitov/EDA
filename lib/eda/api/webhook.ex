defmodule EDA.API.Webhook do
  @moduledoc """
  REST API endpoints for Discord webhooks.

  All functions return `{:ok, result}` or `{:error, reason}`.
  """

  import EDA.HTTP.Client

  @doc "Creates a webhook for a channel."
  @spec create(String.t() | integer(), map()) :: {:ok, map()} | {:error, term()}
  def create(channel_id, opts) do
    post("/channels/#{channel_id}/webhooks", opts)
  end

  @doc "Gets webhooks for a channel."
  @spec list_channel(String.t() | integer()) :: {:ok, [map()]} | {:error, term()}
  def list_channel(channel_id) do
    EDA.HTTP.Client.get("/channels/#{channel_id}/webhooks")
  end

  @doc "Gets webhooks for a guild."
  @spec list_guild(String.t() | integer()) :: {:ok, [map()]} | {:error, term()}
  def list_guild(guild_id) do
    EDA.HTTP.Client.get("/guilds/#{guild_id}/webhooks")
  end

  @doc "Gets a webhook by ID."
  @spec get(String.t() | integer()) :: {:ok, map()} | {:error, term()}
  def get(webhook_id) do
    EDA.HTTP.Client.get("/webhooks/#{webhook_id}")
  end

  @doc "Modifies a webhook."
  @spec modify(String.t() | integer(), map()) :: {:ok, map()} | {:error, term()}
  def modify(webhook_id, opts) do
    patch("/webhooks/#{webhook_id}", opts)
  end

  @doc "Deletes a webhook."
  @spec delete(String.t() | integer()) :: :ok | {:error, term()}
  def delete(webhook_id) do
    case EDA.HTTP.Client.delete("/webhooks/#{webhook_id}") do
      {:ok, _} -> :ok
      error -> error
    end
  end

  @doc "Executes a webhook."
  @spec execute(String.t() | integer(), String.t(), map() | keyword()) ::
          {:ok, map()} | {:error, term()}
  def execute(webhook_id, webhook_token, opts) when is_list(opts) do
    case build_message_payload(opts) do
      {payload, files} ->
        request_multipart(:post, "/webhooks/#{webhook_id}/#{webhook_token}", payload, files)

      payload ->
        post("/webhooks/#{webhook_id}/#{webhook_token}", payload)
    end
  end

  def execute(webhook_id, webhook_token, opts) when is_map(opts) do
    post("/webhooks/#{webhook_id}/#{webhook_token}", opts)
  end
end
