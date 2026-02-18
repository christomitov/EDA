defmodule EDA.API.Invite do
  @moduledoc """
  REST API endpoints for Discord invites.

  All functions return `{:ok, result}` or `{:error, reason}`.
  """

  import EDA.HTTP.Client

  @doc "Gets invites for a channel."
  @spec list_channel(String.t() | integer()) :: {:ok, [map()]} | {:error, term()}
  def list_channel(channel_id) do
    EDA.HTTP.Client.get("/channels/#{channel_id}/invites")
  end

  @doc "Creates an invite for a channel."
  @spec create(String.t() | integer(), keyword() | map()) :: {:ok, map()} | {:error, term()}
  def create(channel_id, opts \\ []) do
    body = if is_list(opts), do: Map.new(opts), else: opts
    post("/channels/#{channel_id}/invites", body)
  end

  @doc "Deletes an invite by code."
  @spec delete(String.t()) :: {:ok, map()} | {:error, term()}
  def delete(invite_code) do
    EDA.HTTP.Client.delete("/invites/#{invite_code}")
  end
end
