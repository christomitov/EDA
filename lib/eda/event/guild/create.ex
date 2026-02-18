defmodule EDA.Event.GuildCreate do
  @moduledoc "Dispatched when a guild becomes available or the bot joins a guild."
  use EDA.Event.Access

  defstruct [
    :id,
    :name,
    :owner_id,
    :icon,
    :channels,
    :members,
    :roles,
    :voice_states,
    :presences,
    :member_count,
    :large,
    :unavailable
  ]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          name: String.t() | nil,
          owner_id: String.t() | nil,
          icon: String.t() | nil,
          channels: [EDA.Channel.t()] | nil,
          members: [EDA.Member.t()] | nil,
          roles: [EDA.Role.t()] | nil,
          voice_states: [map()] | nil,
          presences: [map()] | nil,
          member_count: integer() | nil,
          large: boolean() | nil,
          unavailable: boolean() | nil
        }

  @doc "Converts a raw Discord payload into this event struct."
  @spec from_raw(map()) :: t()
  def from_raw(raw) when is_map(raw) do
    %__MODULE__{
      id: raw["id"],
      name: raw["name"],
      owner_id: raw["owner_id"],
      icon: raw["icon"],
      channels: parse_channels(raw["channels"]),
      members: parse_members(raw["members"]),
      roles: parse_roles(raw["roles"]),
      voice_states: raw["voice_states"],
      presences: raw["presences"],
      member_count: raw["member_count"],
      large: raw["large"],
      unavailable: raw["unavailable"]
    }
  end

  defp parse_channels(nil), do: nil
  defp parse_channels(list) when is_list(list), do: Enum.map(list, &EDA.Channel.from_raw/1)

  defp parse_members(nil), do: nil
  defp parse_members(list) when is_list(list), do: Enum.map(list, &EDA.Member.from_raw/1)

  defp parse_roles(nil), do: nil
  defp parse_roles(list) when is_list(list), do: Enum.map(list, &EDA.Role.from_raw/1)
end
