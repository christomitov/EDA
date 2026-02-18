defmodule EDA.Event.MessageUpdate do
  @moduledoc "Dispatched when a message is updated."
  use EDA.Event.Access

  defstruct [
    :id,
    :channel_id,
    :guild_id,
    :author,
    :content,
    :timestamp,
    :edited_timestamp,
    :tts,
    :mention_everyone,
    :mentions,
    :mention_roles,
    :attachments,
    :embeds,
    :pinned,
    :type,
    :member,
    :referenced_message,
    :message_reference,
    :components,
    :sticker_items
  ]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          channel_id: String.t() | nil,
          guild_id: String.t() | nil,
          author: EDA.User.t() | nil,
          content: String.t() | nil,
          timestamp: String.t() | nil,
          edited_timestamp: String.t() | nil,
          tts: boolean() | nil,
          mention_everyone: boolean() | nil,
          mentions: [EDA.User.t()] | nil,
          mention_roles: [String.t()] | nil,
          attachments: [EDA.Attachment.t()] | nil,
          embeds: [map()] | nil,
          pinned: boolean() | nil,
          type: integer() | nil,
          member: EDA.Member.t() | nil,
          referenced_message: map() | nil,
          message_reference: map() | nil,
          components: [map()] | nil,
          sticker_items: [map()] | nil
        }

  @doc "Converts a raw Discord payload into this event struct."
  @spec from_raw(map()) :: t()
  def from_raw(raw) when is_map(raw) do
    %__MODULE__{
      id: raw["id"],
      channel_id: raw["channel_id"],
      guild_id: raw["guild_id"],
      author: parse_user(raw["author"]),
      content: raw["content"],
      timestamp: raw["timestamp"],
      edited_timestamp: raw["edited_timestamp"],
      tts: raw["tts"],
      mention_everyone: raw["mention_everyone"],
      mentions: parse_users(raw["mentions"]),
      mention_roles: raw["mention_roles"],
      attachments: parse_attachments(raw["attachments"]),
      embeds: raw["embeds"],
      pinned: raw["pinned"],
      type: raw["type"],
      member: parse_member(raw["member"]),
      referenced_message: raw["referenced_message"],
      message_reference: raw["message_reference"],
      components: raw["components"],
      sticker_items: raw["sticker_items"]
    }
  end

  defp parse_user(nil), do: nil
  defp parse_user(raw) when is_map(raw), do: EDA.User.from_raw(raw)

  defp parse_users(nil), do: nil
  defp parse_users(list) when is_list(list), do: Enum.map(list, &EDA.User.from_raw/1)

  defp parse_member(nil), do: nil
  defp parse_member(raw) when is_map(raw), do: EDA.Member.from_raw(raw)

  defp parse_attachments(nil), do: nil
  defp parse_attachments(list) when is_list(list), do: Enum.map(list, &EDA.Attachment.from_raw/1)
end
