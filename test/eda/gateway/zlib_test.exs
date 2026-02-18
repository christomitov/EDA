defmodule EDA.Gateway.ZlibTest do
  # Not async — zlib contexts are bound to the creating process
  use ExUnit.Case

  alias EDA.Gateway.Zlib

  @zlib_suffix <<0x00, 0x00, 0xFF, 0xFF>>

  setup do
    {:ok, zlib} = Zlib.init()
    {:ok, zlib: zlib}
  end

  # Helper: compress a single payload independently (fresh deflate context).
  defp compress(data) do
    z = :zlib.open()
    :zlib.deflateInit(z)
    compressed = :zlib.deflate(z, data, :full)
    :zlib.close(z)
    IO.iodata_to_binary(compressed)
  end

  # Helper: compress multiple payloads using a shared deflate context
  # (mimics Discord's persistent zlib-stream).
  defp compress_stream(payloads) when is_list(payloads) do
    z = :zlib.open()
    :zlib.deflateInit(z)

    results =
      Enum.map(payloads, fn data ->
        IO.iodata_to_binary(:zlib.deflate(z, data, :sync))
      end)

    :zlib.close(z)
    results
  end

  describe "push/2" do
    test "decompresses a complete single frame", %{zlib: zlib} do
      payload = Jason.encode!(%{"op" => 10, "d" => %{"heartbeat_interval" => 41_250}})
      compressed = compress(payload)

      # Compressed with flush ends with the suffix
      assert binary_part(compressed, byte_size(compressed) - 4, 4) == @zlib_suffix

      assert {:ok, result, _zlib} = Zlib.push(zlib, compressed)
      assert result == payload
    end

    test "buffers incomplete frames until suffix arrives", %{zlib: zlib} do
      payload =
        Jason.encode!(%{"op" => 0, "t" => "MESSAGE_CREATE", "d" => %{"content" => "hello"}})

      compressed = compress(payload)

      # Split the compressed data into two parts
      split_point = div(byte_size(compressed), 2)
      <<part1::binary-size(split_point), part2::binary>> = compressed

      # First push: incomplete, no suffix
      assert {:incomplete, zlib} = Zlib.push(zlib, part1)

      # Second push: completes the frame
      assert {:ok, result, _zlib} = Zlib.push(zlib, part2)
      assert result == payload
    end

    test "handles multiple sequential messages with shared context", %{zlib: zlib} do
      messages = [
        Jason.encode!(%{"op" => 10, "d" => %{"heartbeat_interval" => 41_250}}),
        Jason.encode!(%{"op" => 0, "t" => "READY", "d" => %{}}),
        Jason.encode!(%{"op" => 11}),
        Jason.encode!(%{"op" => 1, "d" => 42})
      ]

      # Use a shared deflate context, just like Discord's zlib-stream
      compressed_frames = compress_stream(messages)

      Enum.zip(messages, compressed_frames)
      |> Enum.reduce(zlib, fn {expected, compressed}, zlib ->
        assert {:ok, result, zlib} = Zlib.push(zlib, compressed)
        assert result == expected
        zlib
      end)
    end

    test "handles three-way split frame", %{zlib: zlib} do
      payload = Jason.encode!(%{"op" => 0, "d" => String.duplicate("x", 500)})
      compressed = compress(payload)

      size = byte_size(compressed)
      p1 = div(size, 3)
      p2 = div(size * 2, 3)

      <<chunk1::binary-size(p1), rest::binary>> = compressed
      chunk2_size = p2 - p1
      <<chunk2::binary-size(chunk2_size), chunk3::binary>> = rest

      assert {:incomplete, zlib} = Zlib.push(zlib, chunk1)
      assert {:incomplete, zlib} = Zlib.push(zlib, chunk2)
      assert {:ok, result, _zlib} = Zlib.push(zlib, chunk3)
      assert result == payload
    end

    test "returns error on corrupt data and resets context", %{zlib: zlib} do
      # Feed garbage that ends with the suffix
      garbage = :crypto.strong_rand_bytes(100) <> @zlib_suffix

      assert {:error, :inflate_failed, zlib} = Zlib.push(zlib, garbage)

      # Context should be usable again after reset
      payload = Jason.encode!(%{"op" => 11})
      compressed = compress(payload)
      assert {:ok, result, _zlib} = Zlib.push(zlib, compressed)
      assert result == payload
    end
  end

  describe "reset/1" do
    test "clears buffer and resets context", %{zlib: zlib} do
      payload = Jason.encode!(%{"op" => 0, "d" => %{}})
      compressed = compress(payload)

      # Push partial data
      partial = binary_part(compressed, 0, div(byte_size(compressed), 2))
      assert {:incomplete, zlib} = Zlib.push(zlib, partial)

      # Reset clears the buffer
      zlib = Zlib.reset(zlib)

      # Should work fresh again with independent frame
      new_compressed = compress(payload)
      assert {:ok, result, _zlib} = Zlib.push(zlib, new_compressed)
      assert result == payload
    end
  end

  describe "close/1" do
    test "can be called safely" do
      {:ok, zlib} = Zlib.init()
      assert :ok = Zlib.close(zlib)
    end
  end

  describe "suffix detection" do
    test "frames shorter than 4 bytes are always incomplete", %{zlib: zlib} do
      assert {:incomplete, _zlib} = Zlib.push(zlib, <<0x00>>)
    end

    test "exactly 4-byte suffix without prior data triggers error recovery", %{zlib: zlib} do
      assert {:error, :inflate_failed, _zlib} = Zlib.push(zlib, @zlib_suffix)
    end
  end
end
