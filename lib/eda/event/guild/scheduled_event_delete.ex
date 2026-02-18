defmodule EDA.Event.GuildScheduledEventDelete do
  @moduledoc "Dispatched when a guild scheduled event is deleted."
  use EDA.Event.Access

  defstruct [
    :id,
    :guild_id,
    :channel_id,
    :creator_id,
    :name,
    :description,
    :scheduled_start_time,
    :scheduled_end_time,
    :privacy_level,
    :status,
    :entity_type,
    :entity_id,
    :entity_metadata,
    :creator,
    :user_count
  ]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          guild_id: String.t() | nil,
          channel_id: String.t() | nil,
          creator_id: String.t() | nil,
          name: String.t() | nil,
          description: String.t() | nil,
          scheduled_start_time: String.t() | nil,
          scheduled_end_time: String.t() | nil,
          privacy_level: integer() | nil,
          status: integer() | nil,
          entity_type: integer() | nil,
          entity_id: String.t() | nil,
          entity_metadata: map() | nil,
          creator: map() | nil,
          user_count: integer() | nil
        }
  @doc "Converts a raw Discord payload into this event struct."
  @spec from_raw(map()) :: t()
  def from_raw(raw) when is_map(raw) do
    %__MODULE__{
      id: raw["id"],
      guild_id: raw["guild_id"],
      channel_id: raw["channel_id"],
      creator_id: raw["creator_id"],
      name: raw["name"],
      description: raw["description"],
      scheduled_start_time: raw["scheduled_start_time"],
      scheduled_end_time: raw["scheduled_end_time"],
      privacy_level: raw["privacy_level"],
      status: raw["status"],
      entity_type: raw["entity_type"],
      entity_id: raw["entity_id"],
      entity_metadata: raw["entity_metadata"],
      creator: raw["creator"],
      user_count: raw["user_count"]
    }
  end
end
