defmodule EDA.API.Emoji do
  @moduledoc """
  REST API endpoints for Discord guild emojis.

  All functions return `{:ok, result}` or `{:error, reason}`.
  """

  import EDA.HTTP.Client

  @doc "Lists all emojis for a guild. Returns `EDA.Emoji` structs."
  @spec list(String.t() | integer()) :: {:ok, [EDA.Emoji.t()]} | {:error, term()}
  def list(guild_id) do
    case EDA.HTTP.Client.get("/guilds/#{guild_id}/emojis") do
      {:ok, emojis} -> {:ok, Enum.map(emojis, &EDA.Emoji.from_raw/1)}
      error -> error
    end
  end

  @doc "Gets a guild emoji by ID. Returns an `EDA.Emoji` struct."
  @spec get(String.t() | integer(), String.t() | integer()) ::
          {:ok, EDA.Emoji.t()} | {:error, term()}
  def get(guild_id, emoji_id) do
    case EDA.HTTP.Client.get("/guilds/#{guild_id}/emojis/#{emoji_id}") do
      {:ok, data} -> {:ok, EDA.Emoji.from_raw(data)}
      error -> error
    end
  end

  @doc """
  Creates a guild emoji.

  ## Parameters

  - `guild_id` - The guild ID
  - `params` - Map with:
    - `:name` - Emoji name (required)
    - `:image` - Base64-encoded image data URI (required)
    - `:roles` - List of role IDs allowed to use this emoji (optional)
  """
  @spec create(String.t() | integer(), map()) :: {:ok, EDA.Emoji.t()} | {:error, term()}
  def create(guild_id, params) do
    case post("/guilds/#{guild_id}/emojis", params) do
      {:ok, data} -> {:ok, EDA.Emoji.from_raw(data)}
      error -> error
    end
  end

  @doc "Modifies a guild emoji."
  @spec modify(String.t() | integer(), String.t() | integer(), map()) ::
          {:ok, EDA.Emoji.t()} | {:error, term()}
  def modify(guild_id, emoji_id, params) do
    case patch("/guilds/#{guild_id}/emojis/#{emoji_id}", params) do
      {:ok, data} -> {:ok, EDA.Emoji.from_raw(data)}
      error -> error
    end
  end

  @doc "Deletes a guild emoji."
  @spec delete(String.t() | integer(), String.t() | integer()) :: :ok | {:error, term()}
  def delete(guild_id, emoji_id) do
    case EDA.HTTP.Client.delete("/guilds/#{guild_id}/emojis/#{emoji_id}") do
      {:ok, _} -> :ok
      error -> error
    end
  end
end
