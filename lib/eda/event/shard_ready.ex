defmodule EDA.Event.ShardReady do
  @moduledoc "Fired when a shard finishes loading all its guilds."
  use EDA.Event.Access

  defstruct [:shard_id, :guild_count, :duration_ms]

  @type t :: %__MODULE__{
          shard_id: non_neg_integer() | nil,
          guild_count: non_neg_integer() | nil,
          duration_ms: non_neg_integer() | nil
        }

  @doc "Converts a raw payload into this event struct."
  @spec from_raw(map()) :: t()
  def from_raw(raw) when is_map(raw) do
    %__MODULE__{
      shard_id: raw["shard_id"],
      guild_count: raw["guild_count"],
      duration_ms: raw["duration_ms"]
    }
  end
end
