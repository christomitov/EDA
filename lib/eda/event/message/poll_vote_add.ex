defmodule EDA.Event.MessagePollVoteAdd do
  @moduledoc "Dispatched when a user votes on a poll answer."
  use EDA.Event.Access

  defstruct [:user_id, :channel_id, :message_id, :guild_id, :answer_id]

  @type t :: %__MODULE__{
          user_id: String.t() | nil,
          channel_id: String.t() | nil,
          message_id: String.t() | nil,
          guild_id: String.t() | nil,
          answer_id: integer() | nil
        }

  @doc "Converts a raw Discord payload into this event struct."
  @spec from_raw(map()) :: t()
  def from_raw(raw) when is_map(raw) do
    %__MODULE__{
      user_id: raw["user_id"],
      channel_id: raw["channel_id"],
      message_id: raw["message_id"],
      guild_id: raw["guild_id"],
      answer_id: raw["answer_id"]
    }
  end
end
