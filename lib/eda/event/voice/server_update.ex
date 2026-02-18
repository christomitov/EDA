defmodule EDA.Event.VoiceServerUpdate do
  @moduledoc "Dispatched when a guild's voice server is updated."
  use EDA.Event.Access

  defstruct [:guild_id, :token, :endpoint]

  @type t :: %__MODULE__{
          guild_id: String.t() | nil,
          token: String.t() | nil,
          endpoint: String.t() | nil
        }

  @doc "Converts a raw Discord payload into this event struct."
  @spec from_raw(map()) :: t()
  def from_raw(raw) when is_map(raw) do
    %__MODULE__{guild_id: raw["guild_id"], token: raw["token"], endpoint: raw["endpoint"]}
  end
end
