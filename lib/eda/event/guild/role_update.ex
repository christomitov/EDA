defmodule EDA.Event.GuildRoleUpdate do
  @moduledoc "Dispatched when a guild role is updated."
  use EDA.Event.Access

  defstruct [:guild_id, :role]

  @type t :: %__MODULE__{guild_id: String.t() | nil, role: EDA.Role.t() | nil}

  @doc "Converts a raw Discord payload into this event struct."
  @spec from_raw(map()) :: t()
  def from_raw(raw) when is_map(raw) do
    %__MODULE__{guild_id: raw["guild_id"], role: parse_role(raw["role"])}
  end

  defp parse_role(nil), do: nil
  defp parse_role(raw) when is_map(raw), do: EDA.Role.from_raw(raw)
end
