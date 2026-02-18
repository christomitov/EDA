defmodule EDA.AuditLog.Change do
  @moduledoc "Represents a single change within an audit log entry."
  use EDA.Event.Access

  defstruct [:key, :old_value, :new_value]

  @type t :: %__MODULE__{
          key: String.t() | nil,
          old_value: term(),
          new_value: term()
        }

  @doc "Converts a raw change map into this struct."
  @spec from_raw(map()) :: t()
  def from_raw(raw) when is_map(raw) do
    %__MODULE__{
      key: raw["key"],
      old_value: raw["old_value"],
      new_value: raw["new_value"]
    }
  end
end
