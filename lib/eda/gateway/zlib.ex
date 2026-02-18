defmodule EDA.Gateway.Zlib do
  @moduledoc """
  Zlib-stream decompressor for Discord gateway transport compression.

  Maintains a persistent inflate context across the lifetime of a gateway
  connection, accumulates fragmented frames, and decompresses when the
  zlib sync flush suffix (`0x00 0x00 0xFF 0xFF`) is detected.

  ## Features

  - **Frame buffering** — accumulates fragments until the zlib suffix is detected
  - **Suffix detection** — binary pattern match on the last 4 bytes (no list conversion)
  - **Error recovery** — decompression failures reset the context instead of crashing
  - **Buffer size limit** — prevents unbounded memory growth from malformed streams
  - **Proper lifecycle** — init, reset, close with resource cleanup
  - **Telemetry** — emits events on decompression errors

  ## Usage

      {:ok, zlib} = EDA.Gateway.Zlib.init()

      case EDA.Gateway.Zlib.push(zlib, binary_frame) do
        {:ok, json_binary, zlib} -> # complete message decompressed
        {:incomplete, zlib}      -> # buffered, waiting for more data
        {:error, reason, zlib}   -> # decompression error, context was reset
      end

      zlib = EDA.Gateway.Zlib.reset(zlib)  # on reconnect
      :ok  = EDA.Gateway.Zlib.close(zlib)  # on shutdown
  """

  @zlib_suffix <<0x00, 0x00, 0xFF, 0xFF>>

  # 10 MiB — if the buffer exceeds this, we discard it and reset.
  @max_buffer_size 10 * 1024 * 1024

  defstruct [:context, buffer: <<>>]

  @type t :: %__MODULE__{
          context: :zlib.zstream(),
          buffer: binary()
        }

  @doc """
  Creates a new zlib decompressor with a fresh inflate context.
  """
  @spec init() :: {:ok, t()}
  def init do
    ctx = :zlib.open()
    :zlib.inflateInit(ctx)
    {:ok, %__MODULE__{context: ctx}}
  end

  @doc """
  Pushes a binary frame into the decompressor.

  Returns:
  - `{:ok, decompressed_binary, zlib}` — a complete message was decompressed
  - `{:incomplete, zlib}` — frame buffered, waiting for the zlib suffix
  - `{:error, reason, zlib}` — decompression failed, context has been reset
  """
  @spec push(t(), binary()) :: {:ok, binary(), t()} | {:incomplete, t()} | {:error, term(), t()}
  def push(%__MODULE__{} = state, frame) when is_binary(frame) do
    buffer = state.buffer <> frame

    if buffer_overflow?(buffer) do
      state = reset_state(state)
      {:error, :buffer_overflow, state}
    else
      if complete?(buffer) do
        inflate(state, buffer)
      else
        {:incomplete, %{state | buffer: buffer}}
      end
    end
  end

  @doc """
  Resets the inflate context and clears the buffer.

  Call this when reconnecting to the gateway.
  """
  @spec reset(t()) :: t()
  def reset(%__MODULE__{context: ctx} = state) do
    :zlib.inflateReset(ctx)
    %{state | buffer: <<>>}
  end

  @doc """
  Closes the zlib context and frees resources.

  The struct must not be used after calling this.
  """
  @spec close(t()) :: :ok
  def close(%__MODULE__{context: ctx}) do
    try do
      :zlib.inflateEnd(ctx)
    rescue
      # Context may already be in an inconsistent state
      ErlangError -> :ok
    end

    :zlib.close(ctx)
    :ok
  end

  # -- Private --

  # Check if the buffer ends with the zlib sync flush suffix.
  defp complete?(<<_::binary-size(4), _::binary>> = buffer) do
    suffix_offset = byte_size(buffer) - 4
    binary_part(buffer, suffix_offset, 4) == @zlib_suffix
  end

  defp complete?(_), do: false

  defp buffer_overflow?(buffer), do: byte_size(buffer) > @max_buffer_size

  defp inflate(%__MODULE__{context: ctx} = state, buffer) do
    try do
      result =
        ctx
        |> :zlib.inflate(buffer)
        |> IO.iodata_to_binary()

      {:ok, result, %{state | buffer: <<>>}}
    rescue
      e ->
        :telemetry.execute(
          [:eda, :gateway, :zlib, :error],
          %{},
          %{reason: Exception.message(e)}
        )

        state = reset_state(state)
        {:error, :inflate_failed, state}
    end
  end

  defp reset_state(%__MODULE__{} = state) do
    reset(state)
  end
end
