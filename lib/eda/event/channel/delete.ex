defmodule EDA.Event.ChannelDelete do
  @moduledoc "Dispatched when a channel is deleted."
  use EDA.Event.Access

  defstruct [
    :id,
    :type,
    :guild_id,
    :name,
    :position,
    :permission_overwrites,
    :topic,
    :nsfw,
    :parent_id,
    :rate_limit_per_user,
    :bitrate,
    :user_limit
  ]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          type: integer() | nil,
          guild_id: String.t() | nil,
          name: String.t() | nil,
          position: integer() | nil,
          permission_overwrites: [EDA.PermissionOverwrite.t()] | nil,
          topic: String.t() | nil,
          nsfw: boolean() | nil,
          parent_id: String.t() | nil,
          rate_limit_per_user: integer() | nil,
          bitrate: integer() | nil,
          user_limit: integer() | nil
        }

  @doc "Converts a raw Discord payload into this event struct."
  @spec from_raw(map()) :: t()
  def from_raw(raw) when is_map(raw) do
    %__MODULE__{
      id: raw["id"],
      type: raw["type"],
      guild_id: raw["guild_id"],
      name: raw["name"],
      position: raw["position"],
      permission_overwrites: parse_overwrites(raw["permission_overwrites"]),
      topic: raw["topic"],
      nsfw: raw["nsfw"],
      parent_id: raw["parent_id"],
      rate_limit_per_user: raw["rate_limit_per_user"],
      bitrate: raw["bitrate"],
      user_limit: raw["user_limit"]
    }
  end

  defp parse_overwrites(nil), do: nil

  defp parse_overwrites(list) when is_list(list),
    do: Enum.map(list, &EDA.PermissionOverwrite.from_raw/1)
end
