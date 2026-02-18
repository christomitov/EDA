defmodule EDA.Event.MessageReactionAdd do
  @moduledoc "Dispatched when a user adds a reaction to a message."
  use EDA.Event.Access
  defstruct [:user_id, :channel_id, :message_id, :guild_id, :member, :emoji]

  @type t :: %__MODULE__{
          user_id: String.t() | nil,
          channel_id: String.t() | nil,
          message_id: String.t() | nil,
          guild_id: String.t() | nil,
          member: EDA.Member.t() | nil,
          emoji: EDA.Emoji.t() | nil
        }
  @doc "Converts a raw Discord payload into this event struct."
  @spec from_raw(map()) :: t()
  def from_raw(raw) when is_map(raw) do
    %__MODULE__{
      user_id: raw["user_id"],
      channel_id: raw["channel_id"],
      message_id: raw["message_id"],
      guild_id: raw["guild_id"],
      member: parse_member(raw["member"]),
      emoji: parse_emoji(raw["emoji"])
    }
  end

  defp parse_member(nil), do: nil
  defp parse_member(raw) when is_map(raw), do: EDA.Member.from_raw(raw)

  defp parse_emoji(nil), do: nil
  defp parse_emoji(raw) when is_map(raw), do: EDA.Emoji.from_raw(raw)
end
