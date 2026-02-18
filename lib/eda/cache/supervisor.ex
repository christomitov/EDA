defmodule EDA.Cache.Supervisor do
  @moduledoc """
  Supervisor for cache processes.

  Starts and manages the ETS tables used for caching
  Discord objects (guilds, users, channels).
  """

  use Supervisor

  def start_link(_opts) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    EDA.Cache.Config.setup()

    :ets.new(:eda_unavailable_guilds, [:set, :public, :named_table, read_concurrency: true])

    children = [
      EDA.Cache.Guild,
      EDA.Cache.User,
      EDA.Cache.Channel,
      EDA.Cache.Member,
      EDA.Cache.Role,
      EDA.Cache.VoiceState,
      EDA.Cache.Presence,
      EDA.Cache.Evictor
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
