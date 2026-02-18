defmodule EDA.Event.GuildMemberAdd do
  @moduledoc "Dispatched when a user joins a guild."
  use EDA.Event.Access
  defstruct [:guild_id, :user, :nick, :roles, :joined_at, :deaf, :mute, :pending, :avatar]

  @type t :: %__MODULE__{
          guild_id: String.t() | nil,
          user: EDA.User.t() | nil,
          nick: String.t() | nil,
          roles: [String.t()] | nil,
          joined_at: String.t() | nil,
          deaf: boolean() | nil,
          mute: boolean() | nil,
          pending: boolean() | nil,
          avatar: String.t() | nil
        }

  @doc "Converts a raw Discord payload into this event struct."
  @spec from_raw(map()) :: t()
  def from_raw(raw) when is_map(raw) do
    %__MODULE__{
      guild_id: raw["guild_id"],
      user: parse_user(raw["user"]),
      nick: raw["nick"],
      roles: raw["roles"],
      joined_at: raw["joined_at"],
      deaf: raw["deaf"],
      mute: raw["mute"],
      pending: raw["pending"],
      avatar: raw["avatar"]
    }
  end

  defp parse_user(nil), do: nil
  defp parse_user(raw) when is_map(raw), do: EDA.User.from_raw(raw)
end
