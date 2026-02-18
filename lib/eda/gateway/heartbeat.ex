defmodule EDA.Gateway.Heartbeat do
  @moduledoc """
  Manages heartbeat timing for the Gateway connection.

  Discord requires regular heartbeats to keep the connection alive.
  The interval is provided by Discord in the HELLO payload.
  """

  @doc """
  Schedules the first heartbeat after HELLO.

  Per Discord docs, the first heartbeat should be sent after
  `interval * jitter` where jitter is between 0 and 1.
  """
  @spec start_first(integer()) :: reference()
  def start_first(interval) do
    delay = trunc(interval * :rand.uniform())
    Process.send_after(self(), {:heartbeat}, delay)
  end

  @doc """
  Schedules the next heartbeat at a fixed interval.
  """
  @spec start(integer()) :: reference()
  def start(interval) do
    Process.send_after(self(), {:heartbeat}, interval)
  end

  @doc """
  Cancels a pending heartbeat timer.
  """
  @spec cancel(reference() | nil) :: :ok
  def cancel(nil), do: :ok

  def cancel(ref) do
    Process.cancel_timer(ref)
    :ok
  end
end
