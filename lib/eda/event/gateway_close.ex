defmodule EDA.Event.GatewayClose do
  @moduledoc "Fired when a shard disconnects from the gateway."
  use EDA.Event.Access

  defstruct [:shard_id, :code, :reason, :action, :will_reconnect]

  @type t :: %__MODULE__{
          shard_id: non_neg_integer() | nil,
          code: integer() | nil,
          reason: String.t() | nil,
          action: String.t() | nil,
          will_reconnect: boolean() | nil
        }

  @doc "Converts a raw payload into this event struct."
  @spec from_raw(map()) :: t()
  def from_raw(raw) when is_map(raw) do
    %__MODULE__{
      shard_id: raw["shard_id"],
      code: raw["code"],
      reason: raw["reason"],
      action: raw["action"],
      will_reconnect: raw["will_reconnect"]
    }
  end
end
