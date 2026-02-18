defmodule EDA.API.Gateway do
  @moduledoc """
  REST API endpoint for Discord gateway info.
  """

  @doc "Gets gateway bot info including recommended shard count."
  @spec bot() :: {:ok, map()} | {:error, term()}
  def bot do
    EDA.HTTP.Client.get("/gateway/bot")
  end
end
