defmodule EDA.API.Interaction do
  @moduledoc """
  REST API endpoints for Discord interaction responses.

  All functions return `:ok`, `{:ok, result}`, or `{:error, reason}`.
  """

  import EDA.HTTP.Client

  @doc "Responds to an interaction."
  @spec respond(String.t() | integer(), String.t(), map(), [EDA.File.t()]) ::
          :ok | {:error, term()}
  def respond(interaction_id, interaction_token, payload, files \\ [])

  def respond(interaction_id, interaction_token, payload, []) do
    interaction_request(
      "/interactions/#{interaction_id}/#{interaction_token}/callback",
      payload
    )
  end

  def respond(interaction_id, interaction_token, payload, files) do
    interaction_request_multipart(
      "/interactions/#{interaction_id}/#{interaction_token}/callback",
      payload,
      files
    )
  end

  @doc "Edits the original interaction response."
  @spec edit_response(String.t() | integer(), String.t(), map(), [EDA.File.t()]) ::
          {:ok, map()} | {:error, term()}
  def edit_response(application_id, interaction_token, payload, files \\ [])

  def edit_response(application_id, interaction_token, payload, []) do
    patch("/webhooks/#{application_id}/#{interaction_token}/messages/@original", payload)
  end

  def edit_response(application_id, interaction_token, payload, files) do
    request_multipart(
      :patch,
      "/webhooks/#{application_id}/#{interaction_token}/messages/@original",
      payload,
      files
    )
  end

  @doc "Deletes the original interaction response."
  @spec delete_response(String.t() | integer(), String.t()) :: :ok | {:error, term()}
  def delete_response(application_id, interaction_token) do
    case EDA.HTTP.Client.delete(
           "/webhooks/#{application_id}/#{interaction_token}/messages/@original"
         ) do
      {:ok, _} -> :ok
      error -> error
    end
  end

  @doc "Creates a followup message for an interaction."
  @spec create_followup(String.t() | integer(), String.t(), map(), [EDA.File.t()]) ::
          {:ok, map()} | {:error, term()}
  def create_followup(application_id, interaction_token, payload, files \\ [])

  def create_followup(application_id, interaction_token, payload, []) do
    post("/webhooks/#{application_id}/#{interaction_token}", payload)
  end

  def create_followup(application_id, interaction_token, payload, files) do
    request_multipart(
      :post,
      "/webhooks/#{application_id}/#{interaction_token}",
      payload,
      files
    )
  end

  @doc "Edits a followup message."
  @spec edit_followup(
          String.t() | integer(),
          String.t(),
          String.t() | integer(),
          map(),
          [EDA.File.t()]
        ) :: {:ok, map()} | {:error, term()}
  def edit_followup(application_id, interaction_token, message_id, payload, files \\ [])

  def edit_followup(application_id, interaction_token, message_id, payload, []) do
    patch(
      "/webhooks/#{application_id}/#{interaction_token}/messages/#{message_id}",
      payload
    )
  end

  def edit_followup(application_id, interaction_token, message_id, payload, files) do
    request_multipart(
      :patch,
      "/webhooks/#{application_id}/#{interaction_token}/messages/#{message_id}",
      payload,
      files
    )
  end

  @doc "Deletes a followup message."
  @spec delete_followup(String.t() | integer(), String.t(), String.t() | integer()) ::
          :ok | {:error, term()}
  def delete_followup(application_id, interaction_token, message_id) do
    case EDA.HTTP.Client.delete(
           "/webhooks/#{application_id}/#{interaction_token}/messages/#{message_id}"
         ) do
      {:ok, _} -> :ok
      error -> error
    end
  end
end
