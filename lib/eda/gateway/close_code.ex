defmodule EDA.Gateway.CloseCode do
  @moduledoc "Classifies Discord Gateway close codes into actionable categories."

  @type action :: :reconnect | :resume | :session_reset | :fatal

  @doc "Returns the action to take for a given close code."
  @spec action(integer() | nil) :: action()

  # Resumable — reconnect with existing session
  # 4000 Unknown error, 4001 Unknown opcode, 4002 Decode error,
  # 4003 Not authenticated, 4005 Already authenticated, 4008 Rate limited
  # 1000 Normal, 1001 Going away, 1006 Abnormal (no close frame)
  def action(code) when code in [4000, 4001, 4002, 4003, 4005, 4008, 1000, 1001, 1006],
    do: :resume

  # Session reset — reconnect but must send fresh IDENTIFY
  # 4007 Invalid seq, 4009 Session timed out
  def action(code) when code in [4007, 4009], do: :session_reset

  # Fatal — do NOT reconnect. Configuration error.
  # 4004 Auth failed, 4010 Invalid shard, 4011 Sharding required,
  # 4012 Invalid API version, 4013 Invalid intents, 4014 Disallowed intents
  def action(code) when code in [4004, 4010, 4011, 4012, 4013, 4014], do: :fatal

  # Custom code from our zombie detection
  def action(4900), do: :resume

  # Unknown codes — default to reconnect
  def action(_), do: :reconnect

  @doc "Returns a human-readable description of a close code."
  @spec reason(integer()) :: String.t()
  def reason(4000), do: "Unknown error"
  def reason(4001), do: "Unknown opcode"
  def reason(4002), do: "Decode error"
  def reason(4003), do: "Not authenticated"
  def reason(4004), do: "Authentication failed (invalid token)"
  def reason(4005), do: "Already authenticated"
  def reason(4007), do: "Invalid sequence number"
  def reason(4008), do: "Rate limited"
  def reason(4009), do: "Session timed out"
  def reason(4010), do: "Invalid shard"
  def reason(4011), do: "Sharding required"
  def reason(4012), do: "Invalid API version"
  def reason(4013), do: "Invalid intents"
  def reason(4014), do: "Disallowed intents"
  def reason(4900), do: "Zombie connection (missed heartbeat ACK)"
  def reason(code), do: "Close code #{code}"

  @doc "Returns true if the code indicates a permanent, non-recoverable error."
  @spec fatal?(integer()) :: boolean()
  def fatal?(code), do: action(code) == :fatal
end
