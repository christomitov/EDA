defmodule EDA.Snowflake do
  @moduledoc """
  Utilities for extracting timestamps from Discord snowflake IDs.

  Discord snowflakes encode a timestamp in their upper bits:

      timestamp_ms = (snowflake >>> 22) + discord_epoch

  Where `discord_epoch` is `1_420_070_400_000` (2015-01-01T00:00:00Z).
  """

  @discord_epoch 1_420_070_400_000

  @doc """
  Returns the Discord epoch (2015-01-01T00:00:00Z) in Unix milliseconds.
  """
  @spec discord_epoch() :: integer()
  def discord_epoch, do: @discord_epoch

  @doc """
  Extracts the Unix timestamp in milliseconds from a snowflake ID.

  ## Examples

      iex> EDA.Snowflake.timestamp(175928847299117063)
      1461015601796

  """
  @spec timestamp(integer() | String.t()) :: integer()
  def timestamp(snowflake) when is_binary(snowflake) do
    snowflake |> String.to_integer() |> timestamp()
  end

  def timestamp(snowflake) when is_integer(snowflake) do
    Bitwise.bsr(snowflake, 22) + @discord_epoch
  end

  @doc """
  Returns the creation time of a snowflake as a UTC `DateTime`.

  ## Examples

      iex> EDA.Snowflake.created_at(175928847299117063)
      ~U[2016-04-19 01:00:01.796Z]

  """
  @spec created_at(integer() | String.t()) :: DateTime.t()
  def created_at(snowflake) do
    snowflake |> timestamp() |> DateTime.from_unix!(:millisecond)
  end

  @doc """
  Generates a snowflake ID from a `DateTime`.

  All worker/process/increment bits are set to zero. This is useful for
  comparison and filtering (e.g. "messages older than 14 days"), not for
  creating real Discord entities.

  ## Examples

      iex> dt = EDA.Snowflake.created_at(EDA.Snowflake.from_datetime(~U[2024-01-01 00:00:00Z]))
      iex> DateTime.truncate(dt, :second)
      ~U[2024-01-01 00:00:00Z]

  """
  @spec from_datetime(DateTime.t()) :: integer()
  def from_datetime(%DateTime{} = dt) do
    ms = DateTime.to_unix(dt, :millisecond)
    Bitwise.bsl(ms - @discord_epoch, 22)
  end

  @doc """
  Returns the age of a snowflake in seconds (as a float).

  ## Examples

      iex> EDA.Snowflake.age(175928847299117063) > 0
      true

  """
  @spec age(integer() | String.t()) :: float()
  def age(snowflake) do
    (System.system_time(:millisecond) - timestamp(snowflake)) / 1000
  end
end
