defmodule EDA.Event.InviteCreate do
  @moduledoc "Dispatched when a new invite is created."
  use EDA.Event.Access
  defstruct [:channel_id, :code, :guild_id, :inviter, :max_age, :max_uses, :temporary, :uses]

  @type t :: %__MODULE__{
          channel_id: String.t() | nil,
          code: String.t() | nil,
          guild_id: String.t() | nil,
          inviter: EDA.User.t() | nil,
          max_age: integer() | nil,
          max_uses: integer() | nil,
          temporary: boolean() | nil,
          uses: integer() | nil
        }
  @doc "Converts a raw Discord payload into this event struct."
  @spec from_raw(map()) :: t()
  def from_raw(raw) when is_map(raw) do
    %__MODULE__{
      channel_id: raw["channel_id"],
      code: raw["code"],
      guild_id: raw["guild_id"],
      inviter: parse_user(raw["inviter"]),
      max_age: raw["max_age"],
      max_uses: raw["max_uses"],
      temporary: raw["temporary"],
      uses: raw["uses"]
    }
  end

  defp parse_user(nil), do: nil
  defp parse_user(raw) when is_map(raw), do: EDA.User.from_raw(raw)
end
