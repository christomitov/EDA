defmodule EDA.Event.GuildUpdate do
  @moduledoc "Dispatched when a guild is updated."
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
          channels: [map()] | nil,
          members: [map()] | nil,
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
      channels: raw["channels"],
      members: raw["members"],
      roles: parse_roles(raw["roles"]),
      voice_states: raw["voice_states"],
      presences: raw["presences"],
      member_count: raw["member_count"],
      large: raw["large"],
      unavailable: raw["unavailable"]
    }
  end

  defp parse_roles(nil), do: nil
  defp parse_roles(list) when is_list(list), do: Enum.map(list, &EDA.Role.from_raw/1)
end
