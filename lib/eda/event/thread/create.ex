defmodule EDA.Event.ThreadCreate do
  @moduledoc "Dispatched when a thread is created."
  use EDA.Event.Access

  defstruct [
    :id,
    :guild_id,
    :type,
    :name,
    :parent_id,
    :owner_id,
    :last_message_id,
    :message_count,
    :member_count,
    :thread_metadata
  ]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          guild_id: String.t() | nil,
          type: integer() | nil,
          name: String.t() | nil,
          parent_id: String.t() | nil,
          owner_id: String.t() | nil,
          last_message_id: String.t() | nil,
          message_count: integer() | nil,
          member_count: integer() | nil,
          thread_metadata: map() | nil
        }
  @doc "Converts a raw Discord payload into this event struct."
  @spec from_raw(map()) :: t()
  def from_raw(raw) when is_map(raw) do
    %__MODULE__{
      id: raw["id"],
      guild_id: raw["guild_id"],
      type: raw["type"],
      name: raw["name"],
      parent_id: raw["parent_id"],
      owner_id: raw["owner_id"],
      last_message_id: raw["last_message_id"],
      message_count: raw["message_count"],
      member_count: raw["member_count"],
      thread_metadata: raw["thread_metadata"]
    }
  end
end
