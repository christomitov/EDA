defmodule EDA.Event.StageInstanceUpdate do
  @moduledoc "Dispatched when a stage instance is updated."
  use EDA.Event.Access

  defstruct [
    :id,
    :guild_id,
    :channel_id,
    :topic,
    :privacy_level,
    :discoverable_disabled,
    :guild_scheduled_event_id
  ]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          guild_id: String.t() | nil,
          channel_id: String.t() | nil,
          topic: String.t() | nil,
          privacy_level: integer() | nil,
          discoverable_disabled: boolean() | nil,
          guild_scheduled_event_id: String.t() | nil
        }

  @doc "Converts a raw Discord payload into this event struct."
  @spec from_raw(map()) :: t()
  def from_raw(raw) when is_map(raw) do
    %__MODULE__{
      id: raw["id"],
      guild_id: raw["guild_id"],
      channel_id: raw["channel_id"],
      topic: raw["topic"],
      privacy_level: raw["privacy_level"],
      discoverable_disabled: raw["discoverable_disabled"],
      guild_scheduled_event_id: raw["guild_scheduled_event_id"]
    }
  end
end
