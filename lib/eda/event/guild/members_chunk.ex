defmodule EDA.Event.GuildMembersChunk do
  @moduledoc "Dispatched in response to a guild members request."
  use EDA.Event.Access
  defstruct [:guild_id, :members, :chunk_index, :chunk_count, :not_found, :presences, :nonce]

  @type t :: %__MODULE__{
          guild_id: String.t() | nil,
          members: [EDA.Member.t()] | nil,
          chunk_index: integer() | nil,
          chunk_count: integer() | nil,
          not_found: [String.t()] | nil,
          presences: [map()] | nil,
          nonce: String.t() | nil
        }
  @doc "Converts a raw Discord payload into this event struct."
  @spec from_raw(map()) :: t()
  def from_raw(raw) when is_map(raw) do
    %__MODULE__{
      guild_id: raw["guild_id"],
      members: parse_members(raw["members"]),
      chunk_index: raw["chunk_index"],
      chunk_count: raw["chunk_count"],
      not_found: raw["not_found"],
      presences: raw["presences"],
      nonce: raw["nonce"]
    }
  end

  defp parse_members(nil), do: nil
  defp parse_members(list) when is_list(list), do: Enum.map(list, &EDA.Member.from_raw/1)
end
