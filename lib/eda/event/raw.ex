defmodule EDA.Event.Raw do
  @moduledoc "Fallback for unrecognized Discord events."

  use EDA.Event.Access

  defstruct [:event_type, :data]

  @type t :: %__MODULE__{
          event_type: String.t(),
          data: map()
        }

  @doc "Wraps an unknown event with atomized top-level keys."
  @spec from_raw(String.t(), map()) :: t()
  def from_raw(event_type, data) do
    %__MODULE__{event_type: event_type, data: EDA.Event.Helpers.atomize(data)}
  end
end
