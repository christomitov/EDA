defmodule EDA.Gateway.ShardManagerTest do
  use ExUnit.Case, async: true

  alias EDA.Gateway.ShardManager

  describe "shard_for_guild/1" do
    setup do
      :persistent_term.put(:eda_total_shards, 4)

      on_exit(fn ->
        :persistent_term.put(:eda_total_shards, 1)
      end)
    end

    test "routes guild to correct shard (integer)" do
      # guild_id >> 22 gives the internal creation increment
      # 175_928_847_299_117_063 >> 22 = 41_944_370 → 41_944_370 rem 4 = 2
      guild_id = 175_928_847_299_117_063
      assert ShardManager.shard_for_guild(guild_id) == rem(Bitwise.bsr(guild_id, 22), 4)
    end

    test "routes guild to correct shard (string)" do
      guild_id = "175928847299117063"
      expected = rem(Bitwise.bsr(175_928_847_299_117_063, 22), 4)
      assert ShardManager.shard_for_guild(guild_id) == expected
    end

    test "always returns 0 when total_shards is 1" do
      :persistent_term.put(:eda_total_shards, 1)
      assert ShardManager.shard_for_guild(175_928_847_299_117_063) == 0
      assert ShardManager.shard_for_guild(999_999_999_999_999_999) == 0
    end

    test "distributes across shards" do
      guild_ids = [
        100_000_000_000_000_000,
        200_000_000_000_000_000,
        300_000_000_000_000_000,
        400_000_000_000_000_000
      ]

      results = Enum.map(guild_ids, &ShardManager.shard_for_guild/1)
      assert Enum.all?(results, &(&1 >= 0 and &1 < 4))
    end
  end

  describe "resolve_shards/2" do
    test ":auto uses recommended count" do
      assert {[0, 1, 2], 3} = ShardManager.resolve_shards(:auto, 3)
    end

    test ":auto with 1 shard" do
      assert {[0], 1} = ShardManager.resolve_shards(:auto, 1)
    end

    test "integer overrides recommended" do
      assert {[0, 1, 2, 3], 4} = ShardManager.resolve_shards(4, 2)
    end

    test "range tuple for multi-node" do
      assert {[0, 1], 4} = ShardManager.resolve_shards({0..1, 4}, 2)
    end

    test "range with non-contiguous list" do
      assert {[0, 3], 4} = ShardManager.resolve_shards({[0, 3], 4}, 2)
    end
  end

  describe "reconnect_delay/1" do
    test "first attempt is around 1s" do
      delay = ShardManager.reconnect_delay(1)
      # 1000 base + up to 1000 jitter
      assert delay >= 1000
      assert delay <= 2000
    end

    test "exponential growth" do
      d1 = ShardManager.reconnect_delay(1)
      d2 = ShardManager.reconnect_delay(2)
      d3 = ShardManager.reconnect_delay(3)

      # Base doubles: 1000, 2000, 4000 (plus jitter)
      assert d2 > d1
      assert d3 > d2
    end

    test "caps at 30s + jitter" do
      delay = ShardManager.reconnect_delay(100)
      assert delay >= 30_000
      assert delay <= 31_000
    end
  end

  describe "total_shards/0" do
    test "returns persistent_term value" do
      :persistent_term.put(:eda_total_shards, 7)
      assert ShardManager.total_shards() == 7
      :persistent_term.put(:eda_total_shards, 1)
    end

    test "defaults to 1" do
      :persistent_term.erase(:eda_total_shards)
      assert ShardManager.total_shards() == 1
      :persistent_term.put(:eda_total_shards, 1)
    end
  end
end
