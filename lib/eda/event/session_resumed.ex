defmodule EDA.Event.SessionResumed do
  @moduledoc "Fired when a shard successfully resumes a previous session."
  use EDA.Event.Access

  defstruct [:shard_id]

  @type t :: %__MODULE__{shard_id: non_neg_integer() | nil}

  @doc "Converts a raw payload into this event struct."
  @spec from_raw(map()) :: t()
  def from_raw(raw) when is_map(raw) do
    %__MODULE__{
      shard_id: raw["shard_id"]
    }
  end
end
