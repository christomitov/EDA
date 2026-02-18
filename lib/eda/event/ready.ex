defmodule EDA.Event.Ready do
  @moduledoc "Dispatched when the client has completed the initial handshake."
  use EDA.Event.Access
  defstruct [:v, :user, :guilds, :session_id, :resume_gateway_url, :shard, :application]

  @type t :: %__MODULE__{
          v: integer() | nil,
          user: EDA.User.t() | nil,
          guilds: [map()] | nil,
          session_id: String.t() | nil,
          resume_gateway_url: String.t() | nil,
          shard: [integer()] | nil,
          application: map() | nil
        }

  @doc "Converts a raw Discord payload into this event struct."
  @spec from_raw(map()) :: t()
  def from_raw(raw) when is_map(raw) do
    %__MODULE__{
      v: raw["v"],
      user: parse_user(raw["user"]),
      guilds: raw["guilds"],
      session_id: raw["session_id"],
      resume_gateway_url: raw["resume_gateway_url"],
      shard: raw["shard"],
      application: raw["application"]
    }
  end

  defp parse_user(nil), do: nil
  defp parse_user(raw) when is_map(raw), do: EDA.User.from_raw(raw)
end
