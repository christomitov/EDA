defmodule EDA.Event.ThreadListSync do
  @moduledoc "Dispatched when the current user gains access to a channel."
  use EDA.Event.Access
  defstruct [:guild_id, :channel_ids, :threads, :members]

  @type t :: %__MODULE__{
          guild_id: String.t() | nil,
          channel_ids: [String.t()] | nil,
          threads: [map()] | nil,
          members: [map()] | nil
        }
  @doc "Converts a raw Discord payload into this event struct."
  @spec from_raw(map()) :: t()
  def from_raw(raw) when is_map(raw) do
    %__MODULE__{
      guild_id: raw["guild_id"],
      channel_ids: raw["channel_ids"],
      threads: raw["threads"],
      members: raw["members"]
    }
  end
end
