defmodule EDA.Event.ThreadDelete do
  @moduledoc "Dispatched when a thread is deleted."
  use EDA.Event.Access
  defstruct [:id, :guild_id, :parent_id, :type]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          guild_id: String.t() | nil,
          parent_id: String.t() | nil,
          type: integer() | nil
        }
  @doc "Converts a raw Discord payload into this event struct."
  @spec from_raw(map()) :: t()
  def from_raw(raw) when is_map(raw) do
    %__MODULE__{
      id: raw["id"],
      guild_id: raw["guild_id"],
      parent_id: raw["parent_id"],
      type: raw["type"]
    }
  end
end
