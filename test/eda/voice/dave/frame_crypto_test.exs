defmodule EDA.Voice.Dave.FrameCryptoTest do
  use ExUnit.Case, async: true

  alias EDA.Voice.Dave.FrameCrypto

  @key :crypto.strong_rand_bytes(16)

  describe "encrypt/3 and decrypt/2 round-trip" do
    test "encrypts and decrypts back to the original frame" do
      frame = <<0xFC, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10>>
      encrypted = FrameCrypto.encrypt(frame, @key, 0)
      assert {:ok, ^frame} = FrameCrypto.decrypt(encrypted, @key)
    end

    test "first byte (TOC) remains in clear" do
      frame = <<0xAB, 100, 200, 255>>
      encrypted = FrameCrypto.encrypt(frame, @key, 42)
      assert <<0xAB, _rest::binary>> = encrypted
    end

    test "works with various frame sizes" do
      for size <- [2, 10, 100, 960] do
        frame = <<0xFC, :crypto.strong_rand_bytes(size - 1)::binary>>
        encrypted = FrameCrypto.encrypt(frame, @key, size)
        assert {:ok, ^frame} = FrameCrypto.decrypt(encrypted, @key)
      end
    end

    test "works with increasing nonces" do
      frame = <<0xFC, 1, 2, 3>>

      for nonce <- [0, 1, 100, 0xFFFFFFFF] do
        encrypted = FrameCrypto.encrypt(frame, @key, nonce)
        assert {:ok, ^frame} = FrameCrypto.decrypt(encrypted, @key)
      end
    end

    test "encrypted frame ends with magic marker" do
      frame = <<0xFC, 1, 2, 3, 4, 5>>
      encrypted = FrameCrypto.encrypt(frame, @key, 0)
      size = byte_size(encrypted)
      assert <<_::binary-size(size - 2), 0xFA, 0xFA>> = encrypted
    end
  end

  describe "decrypt/2 error cases" do
    test "wrong key returns :error" do
      frame = <<0xFC, 1, 2, 3, 4, 5>>
      encrypted = FrameCrypto.encrypt(frame, @key, 0)
      wrong_key = :crypto.strong_rand_bytes(16)
      assert :error = FrameCrypto.decrypt(encrypted, wrong_key)
    end

    test "modified ciphertext returns :error" do
      frame = <<0xFC, 1, 2, 3, 4, 5>>
      encrypted = FrameCrypto.encrypt(frame, @key, 0)
      # Flip a bit in the ciphertext (byte 2, after the unencrypted prefix)
      <<prefix::binary-1, byte, rest::binary>> = encrypted
      tampered = <<prefix::binary, Bitwise.bxor(byte, 0xFF), rest::binary>>
      assert :error = FrameCrypto.decrypt(tampered, @key)
    end

    test "truncated frame returns :error" do
      assert :error = FrameCrypto.decrypt(<<>>, @key)
      assert :error = FrameCrypto.decrypt(<<1, 2>>, @key)
    end

    test "invalid key size returns :error" do
      frame = <<0xFC, 1, 2, 3>>
      encrypted = FrameCrypto.encrypt(frame, @key, 0)
      assert :error = FrameCrypto.decrypt(encrypted, <<1, 2, 3>>)
    end

    test "missing magic marker returns :error" do
      frame = <<0xFC, 1, 2, 3, 4, 5>>
      encrypted = FrameCrypto.encrypt(frame, @key, 0)
      # Replace magic marker with garbage
      size = byte_size(encrypted) - 2
      <<body::binary-size(size), _::binary-2>> = encrypted
      tampered = <<body::binary, 0x00, 0x00>>
      assert :error = FrameCrypto.decrypt(tampered, @key)
    end
  end

  describe "encode_leb128/1" do
    test "single byte for values < 128" do
      assert <<0>> = FrameCrypto.encode_leb128(0)
      assert <<1>> = FrameCrypto.encode_leb128(1)
      assert <<127>> = FrameCrypto.encode_leb128(127)
    end

    test "multi-byte for values >= 128" do
      encoded = FrameCrypto.encode_leb128(128)
      assert byte_size(encoded) == 2

      encoded = FrameCrypto.encode_leb128(16_384)
      assert byte_size(encoded) == 3
    end
  end
end
