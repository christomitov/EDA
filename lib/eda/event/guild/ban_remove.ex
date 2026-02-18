defmodule EDA.Event.GuildBanRemove do
  @moduledoc "Dispatched when a user is unbanned from a guild."
  use EDA.Event.Access
  defstruct [:guild_id, :user]
  @type t :: %__MODULE__{guild_id: String.t() | nil, user: EDA.User.t() | nil}
  @doc "Converts a raw Discord payload into this event struct."
  @spec from_raw(map()) :: t()
  def from_raw(raw) when is_map(raw) do
    %__MODULE__{guild_id: raw["guild_id"], user: parse_user(raw["user"])}
  end

  defp parse_user(nil), do: nil
  defp parse_user(raw) when is_map(raw), do: EDA.User.from_raw(raw)
end
