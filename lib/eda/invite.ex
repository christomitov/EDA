defmodule EDA.Invite do
  @moduledoc "Represents a Discord invite."
  use EDA.Event.Access

  defstruct [
    :code,
    :guild_id,
    :channel_id,
    :inviter,
    :target_user,
    :target_type,
    :max_age,
    :max_uses,
    :uses,
    :temporary
  ]

  @type t :: %__MODULE__{
          code: String.t() | nil,
          guild_id: String.t() | nil,
          channel_id: String.t() | nil,
          inviter: EDA.User.t() | nil,
          target_user: EDA.User.t() | nil,
          target_type: integer() | nil,
          max_age: integer() | nil,
          max_uses: integer() | nil,
          uses: integer() | nil,
          temporary: boolean() | nil
        }

  @spec from_raw(map()) :: t()
  def from_raw(raw) when is_map(raw) do
    %__MODULE__{
      code: raw["code"],
      guild_id: raw["guild_id"],
      channel_id: raw["channel_id"],
      inviter: parse_user(raw["inviter"]),
      target_user: parse_user(raw["target_user"]),
      target_type: raw["target_type"],
      max_age: raw["max_age"],
      max_uses: raw["max_uses"],
      uses: raw["uses"],
      temporary: raw["temporary"]
    }
  end

  defp parse_user(nil), do: nil
  defp parse_user(raw) when is_map(raw), do: EDA.User.from_raw(raw)
end
