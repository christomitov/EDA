defmodule EDA.API.AutoMod do
  @moduledoc """
  REST API endpoints for Discord Auto Moderation rules.

  All functions return `{:ok, result}` or `{:error, reason}`.
  """

  import EDA.HTTP.Client

  @doc """
  Lists all Auto Moderation rules for a guild.

  Returns a list of `EDA.AutoMod` structs.
  """
  @spec list(String.t() | integer()) :: {:ok, [EDA.AutoMod.t()]} | {:error, term()}
  def list(guild_id) do
    case get("/guilds/#{guild_id}/auto-moderation/rules") do
      {:ok, rules} -> {:ok, Enum.map(rules, &EDA.AutoMod.from_raw/1)}
      error -> error
    end
  end

  @doc """
  Gets a single Auto Moderation rule by ID.

  Returns an `EDA.AutoMod` struct.
  """
  @spec get_rule(String.t() | integer(), String.t() | integer()) ::
          {:ok, EDA.AutoMod.t()} | {:error, term()}
  def get_rule(guild_id, rule_id) do
    case get("/guilds/#{guild_id}/auto-moderation/rules/#{rule_id}") do
      {:ok, data} -> {:ok, EDA.AutoMod.from_raw(data)}
      error -> error
    end
  end

  @doc """
  Creates an Auto Moderation rule in a guild.

  ## Parameters

  - `guild_id` - The guild ID
  - `params` - Map with:
    - `:name` - Rule name (required, max 100 chars)
    - `:event_type` - Event type (required, 1 = message_send, 2 = member_update)
    - `:trigger_type` - Trigger type (required, see `EDA.AutoMod`)
    - `:trigger_metadata` - Trigger metadata map (optional, varies by trigger type)
    - `:actions` - List of action maps (required)
    - `:enabled` - Whether the rule is enabled (optional, default false)
    - `:exempt_roles` - List of exempt role IDs (optional, max 20)
    - `:exempt_channels` - List of exempt channel IDs (optional, max 50)

  Returns an `EDA.AutoMod` struct.
  """
  @spec create(String.t() | integer(), map()) :: {:ok, EDA.AutoMod.t()} | {:error, term()}
  def create(guild_id, params) do
    case post("/guilds/#{guild_id}/auto-moderation/rules", params) do
      {:ok, data} -> {:ok, EDA.AutoMod.from_raw(data)}
      error -> error
    end
  end

  @doc """
  Modifies an Auto Moderation rule.

  Accepts the same parameters as `create/2` (all optional).
  Returns an `EDA.AutoMod` struct.
  """
  @spec modify(String.t() | integer(), String.t() | integer(), map()) ::
          {:ok, EDA.AutoMod.t()} | {:error, term()}
  def modify(guild_id, rule_id, params) do
    case patch("/guilds/#{guild_id}/auto-moderation/rules/#{rule_id}", params) do
      {:ok, data} -> {:ok, EDA.AutoMod.from_raw(data)}
      error -> error
    end
  end

  @doc "Deletes an Auto Moderation rule."
  @spec delete_rule(String.t() | integer(), String.t() | integer()) :: :ok | {:error, term()}
  def delete_rule(guild_id, rule_id) do
    case delete("/guilds/#{guild_id}/auto-moderation/rules/#{rule_id}") do
      {:ok, _} -> :ok
      error -> error
    end
  end
end
