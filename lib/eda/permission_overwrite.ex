defmodule EDA.PermissionOverwrite do
  @moduledoc "Represents a Discord channel permission overwrite."
  use EDA.Event.Access

  defstruct [:id, :type, :allow, :deny]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          type: integer() | nil,
          allow: String.t() | nil,
          deny: String.t() | nil
        }

  @spec from_raw(map()) :: t()
  def from_raw(raw) when is_map(raw) do
    %__MODULE__{
      id: raw["id"],
      type: raw["type"],
      allow: raw["allow"],
      deny: raw["deny"]
    }
  end
end
