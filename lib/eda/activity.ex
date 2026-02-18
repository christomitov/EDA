defmodule EDA.Activity do
  @moduledoc "Represents a Discord presence activity."
  use EDA.Event.Access

  defstruct [
    :name,
    :type,
    :url,
    :created_at,
    :timestamps,
    :application_id,
    :details,
    :state,
    :emoji,
    :party,
    :assets,
    :secrets,
    :instance,
    :flags,
    :buttons
  ]

  @type t :: %__MODULE__{
          name: String.t() | nil,
          type: integer() | nil,
          url: String.t() | nil,
          created_at: integer() | nil,
          timestamps: map() | nil,
          application_id: String.t() | nil,
          details: String.t() | nil,
          state: String.t() | nil,
          emoji: EDA.Emoji.t() | nil,
          party: map() | nil,
          assets: map() | nil,
          secrets: map() | nil,
          instance: boolean() | nil,
          flags: integer() | nil,
          buttons: [map()] | nil
        }

  @spec from_raw(map()) :: t()
  def from_raw(raw) when is_map(raw) do
    %__MODULE__{
      name: raw["name"],
      type: raw["type"],
      url: raw["url"],
      created_at: raw["created_at"],
      timestamps: raw["timestamps"],
      application_id: raw["application_id"],
      details: raw["details"],
      state: raw["state"],
      emoji: parse_emoji(raw["emoji"]),
      party: raw["party"],
      assets: raw["assets"],
      secrets: raw["secrets"],
      instance: raw["instance"],
      flags: raw["flags"],
      buttons: raw["buttons"]
    }
  end

  defp parse_emoji(nil), do: nil
  defp parse_emoji(raw) when is_map(raw), do: EDA.Emoji.from_raw(raw)
end
