defmodule EDA.Event.InteractionCreate do
  @moduledoc "Dispatched when a user uses an application command or component."
  use EDA.Event.Access

  defstruct [
    :id,
    :application_id,
    :type,
    :data,
    :guild_id,
    :channel_id,
    :member,
    :user,
    :token,
    :message,
    :app_permissions,
    :locale,
    :guild_locale,
    :entitlements
  ]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          application_id: String.t() | nil,
          type: integer() | nil,
          data: map() | nil,
          guild_id: String.t() | nil,
          channel_id: String.t() | nil,
          member: EDA.Member.t() | nil,
          user: EDA.User.t() | nil,
          token: String.t() | nil,
          message: EDA.Message.t() | nil,
          app_permissions: String.t() | nil,
          locale: String.t() | nil,
          guild_locale: String.t() | nil,
          entitlements: [map()] | nil
        }
  @doc "Converts a raw Discord payload into this event struct."
  @spec from_raw(map()) :: t()
  def from_raw(raw) when is_map(raw) do
    %__MODULE__{
      id: raw["id"],
      application_id: raw["application_id"],
      type: raw["type"],
      data: raw["data"],
      guild_id: raw["guild_id"],
      channel_id: raw["channel_id"],
      member: parse_member(raw["member"]),
      user: parse_user(raw["user"]),
      token: raw["token"],
      message: parse_message(raw["message"]),
      app_permissions: raw["app_permissions"],
      locale: raw["locale"],
      guild_locale: raw["guild_locale"],
      entitlements: raw["entitlements"]
    }
  end

  defp parse_user(nil), do: nil
  defp parse_user(raw) when is_map(raw), do: EDA.User.from_raw(raw)

  defp parse_member(nil), do: nil
  defp parse_member(raw) when is_map(raw), do: EDA.Member.from_raw(raw)

  defp parse_message(nil), do: nil
  defp parse_message(raw) when is_map(raw), do: EDA.Message.from_raw(raw)
end
