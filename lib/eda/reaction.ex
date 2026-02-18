defmodule EDA.Reaction do
  @moduledoc "Represents a Discord message reaction."
  use EDA.Event.Access

  defstruct [:count, :me, :emoji]

  @type t :: %__MODULE__{
          count: integer() | nil,
          me: boolean() | nil,
          emoji: EDA.Emoji.t() | nil
        }

  @spec from_raw(map()) :: t()
  def from_raw(raw) when is_map(raw) do
    %__MODULE__{
      count: raw["count"],
      me: raw["me"],
      emoji: parse_emoji(raw["emoji"])
    }
  end

  defp parse_emoji(nil), do: nil
  defp parse_emoji(raw) when is_map(raw), do: EDA.Emoji.from_raw(raw)
end
