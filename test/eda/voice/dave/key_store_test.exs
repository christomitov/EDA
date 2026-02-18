defmodule EDA.Voice.Dave.KeyStoreTest do
  use ExUnit.Case, async: true

  alias EDA.Voice.Dave.KeyStore

  describe "new/0" do
    test "creates an empty key store" do
      store = KeyStore.new()
      assert store.keys == %{}
      assert store.current_epoch == 0
      assert store.self_key == nil
      assert store.self_nonce == 0
    end
  end

  describe "put_sender_key/4 and get_sender_key/3" do
    test "stores and retrieves a key by ssrc and epoch" do
      key = :crypto.strong_rand_bytes(16)

      store =
        KeyStore.new()
        |> KeyStore.put_sender_key(12_345, 1, key)

      assert KeyStore.get_sender_key(store, 12_345, 1) == key
    end

    test "returns nil for missing keys" do
      store = KeyStore.new()
      assert KeyStore.get_sender_key(store, 999, 0) == nil
    end

    test "distinguishes between different ssrc/epoch combos" do
      key1 = :crypto.strong_rand_bytes(16)
      key2 = :crypto.strong_rand_bytes(16)

      store =
        KeyStore.new()
        |> KeyStore.put_sender_key(100, 1, key1)
        |> KeyStore.put_sender_key(100, 2, key2)

      assert KeyStore.get_sender_key(store, 100, 1) == key1
      assert KeyStore.get_sender_key(store, 100, 2) == key2
    end
  end

  describe "advance_epoch/3" do
    test "updates epoch, self_key, and resets nonce" do
      key = :crypto.strong_rand_bytes(16)

      store =
        KeyStore.new()
        |> KeyStore.advance_epoch(5, key)

      assert store.current_epoch == 5
      assert store.self_key == key
      assert store.self_nonce == 0
    end
  end

  describe "next_nonce/1" do
    test "returns incrementing nonces" do
      store = KeyStore.new()

      {n0, store} = KeyStore.next_nonce(store)
      {n1, store} = KeyStore.next_nonce(store)
      {n2, _store} = KeyStore.next_nonce(store)

      assert n0 == 0
      assert n1 == 1
      assert n2 == 2
    end
  end

  describe "prune_old_epochs/2" do
    test "removes keys from old epochs" do
      key = :crypto.strong_rand_bytes(16)

      store =
        KeyStore.new()
        |> KeyStore.put_sender_key(1, 0, key)
        |> KeyStore.put_sender_key(1, 1, key)
        |> KeyStore.put_sender_key(1, 2, key)
        |> KeyStore.put_sender_key(1, 3, key)
        |> KeyStore.advance_epoch(3, key)
        |> KeyStore.prune_old_epochs(2)

      assert KeyStore.get_sender_key(store, 1, 0) == nil
      assert KeyStore.get_sender_key(store, 1, 1) == nil
      assert KeyStore.get_sender_key(store, 1, 2) == key
      assert KeyStore.get_sender_key(store, 1, 3) == key
    end

    test "keeps all keys when within retention window" do
      key = :crypto.strong_rand_bytes(16)

      store =
        KeyStore.new()
        |> KeyStore.put_sender_key(1, 0, key)
        |> KeyStore.put_sender_key(1, 1, key)
        |> KeyStore.advance_epoch(1, key)
        |> KeyStore.prune_old_epochs(2)

      assert KeyStore.get_sender_key(store, 1, 0) == key
      assert KeyStore.get_sender_key(store, 1, 1) == key
    end
  end
end
