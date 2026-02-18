defmodule EDA.Event.ThreadMembersUpdate do
  @moduledoc "Dispatched when members are added or removed from a thread."
  use EDA.Event.Access
  defstruct [:id, :guild_id, :member_count, :added_members, :removed_member_ids]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          guild_id: String.t() | nil,
          member_count: integer() | nil,
          added_members: [map()] | nil,
          removed_member_ids: [String.t()] | nil
        }
  @doc "Converts a raw Discord payload into this event struct."
  @spec from_raw(map()) :: t()
  def from_raw(raw) when is_map(raw) do
    %__MODULE__{
      id: raw["id"],
      guild_id: raw["guild_id"],
      member_count: raw["member_count"],
      added_members: raw["added_members"],
      removed_member_ids: raw["removed_member_ids"]
    }
  end
end
