defmodule EDA.Event.GuildDelete do
  @moduledoc "Dispatched when a guild becomes unavailable or the bot is removed."
  use EDA.Event.Access
  defstruct [:id, :unavailable]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          unavailable: boolean() | nil
        }

  @doc "Converts a raw Discord payload into this event struct."
  @spec from_raw(map()) :: t()
  def from_raw(raw) when is_map(raw) do
    %__MODULE__{
      id: raw["id"],
      unavailable: raw["unavailable"]
    }
  end
end
