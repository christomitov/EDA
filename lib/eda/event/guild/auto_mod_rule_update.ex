defmodule EDA.Event.AutoModRuleUpdate do
  @moduledoc "Dispatched when an Auto Moderation rule is updated."
  use EDA.Event.Access

  defstruct [:rule]

  @type t :: %__MODULE__{rule: EDA.AutoMod.t() | nil}

  @doc "Converts a raw Discord payload into this event struct."
  @spec from_raw(map()) :: t()
  def from_raw(raw) when is_map(raw) do
    %__MODULE__{rule: EDA.AutoMod.from_raw(raw)}
  end
end
