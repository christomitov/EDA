defmodule EDA.Cache.EvictorTest do
  use ExUnit.Case

  alias EDA.Cache.Evictor

  @test_table :eda_evictor_test_main
  @ts_table :eda_evictor_test_main_ts
  @ord_table :eda_evictor_test_main_ord

  setup do
    for t <- [@test_table, @ts_table, @ord_table] do
      if :ets.whereis(t) != :undefined, do: :ets.delete(t)
    end

    :ets.new(@test_table, [:set, :public, :named_table])
    :ets.new(@ts_table, [:set, :public, :named_table, write_concurrency: true])
    :ets.new(@ord_table, [:ordered_set, :public, :named_table, write_concurrency: true])

    :persistent_term.put({:eda_evictor, @test_table}, {@ts_table, @ord_table, 10})

    on_exit(fn ->
      :persistent_term.erase({:eda_evictor, @test_table})
    end)
  end

  describe "touch/2" do
    test "no-op when cache has no max_size" do
      :persistent_term.erase({:eda_evictor, @test_table})
      assert Evictor.touch(@test_table, "key1") == :ok
      assert :ets.info(@ts_table, :size) == 0
    end

    test "records in shadow tables when max_size configured" do
      Evictor.touch(@test_table, "key1")

      assert :ets.info(@ts_table, :size) == 1
      assert :ets.info(@ord_table, :size) == 1
      [{_, mono_time}] = :ets.lookup(@ts_table, "key1")
      assert is_integer(mono_time)
    end

    test "re-insert updates order without duplicates" do
      Evictor.touch(@test_table, "key1")
      [{_, time1}] = :ets.lookup(@ts_table, "key1")
      Process.sleep(1)

      Evictor.touch(@test_table, "key1")
      [{_, time2}] = :ets.lookup(@ts_table, "key1")

      assert time2 > time1
      assert :ets.info(@ts_table, :size) == 1
      assert :ets.info(@ord_table, :size) == 1
    end
  end

  describe "remove/2" do
    test "cleans shadow tables" do
      Evictor.touch(@test_table, "key1")
      assert :ets.info(@ts_table, :size) == 1

      Evictor.remove(@test_table, "key1")
      assert :ets.info(@ts_table, :size) == 0
      assert :ets.info(@ord_table, :size) == 0
    end

    test "no-op for unknown key" do
      assert Evictor.remove(@test_table, "nonexistent") == :ok
    end
  end

  describe "evict_table/4" do
    test "oldest entries are evicted first when over max_size" do
      max = 5

      for i <- 1..8 do
        key = "k#{i}"
        :ets.insert(@test_table, {key, %{"id" => key}})
        Evictor.touch(@test_table, key)
        Process.sleep(1)
      end

      assert :ets.info(@test_table, :size) == 8

      Evictor.evict_table(@test_table, @ts_table, @ord_table, max)

      assert :ets.info(@test_table, :size) == max
      assert :ets.lookup(@test_table, "k1") == []
      assert :ets.lookup(@test_table, "k2") == []
      assert :ets.lookup(@test_table, "k3") == []
      assert :ets.lookup(@test_table, "k6") != []
      assert :ets.lookup(@test_table, "k7") != []
      assert :ets.lookup(@test_table, "k8") != []
    end

    test "orphaned shadow entries are cleaned up" do
      # Add shadow entries without main table entries (orphans)
      for i <- 1..3 do
        Evictor.touch(@test_table, "orphan#{i}")
        Process.sleep(1)
      end

      # Add real entries that exceed max
      for i <- 1..4 do
        key = "real#{i}"
        :ets.insert(@test_table, {key, %{"id" => key}})
        Evictor.touch(@test_table, key)
        Process.sleep(1)
      end

      Evictor.evict_table(@test_table, @ts_table, @ord_table, 2)

      assert :ets.info(@test_table, :size) == 2
    end

    test "composite keys work correctly" do
      for i <- 1..4 do
        key = {"guild1", "user#{i}"}
        :ets.insert(@test_table, {key, %{"id" => i}})
        Evictor.touch(@test_table, key)
        Process.sleep(1)
      end

      Evictor.evict_table(@test_table, @ts_table, @ord_table, 2)

      assert :ets.info(@test_table, :size) == 2
      assert :ets.lookup(@test_table, {"guild1", "user1"}) == []
      assert :ets.lookup(@test_table, {"guild1", "user4"}) != []
    end

    test "telemetry [:eda, :cache, :evict] is emitted" do
      :telemetry.attach(
        "evict-test-#{inspect(self())}",
        [:eda, :cache, :evict],
        fn _event, measurements, _metadata, pid ->
          send(pid, {:evicted, measurements.count})
        end,
        self()
      )

      for i <- 1..5 do
        key = "t#{i}"
        :ets.insert(@test_table, {key, %{}})
        Evictor.touch(@test_table, key)
        Process.sleep(1)
      end

      Evictor.evict_table(@test_table, @ts_table, @ord_table, 2)

      assert_received {:evicted, 3}

      :telemetry.detach("evict-test-#{inspect(self())}")
    end

    test "no-op when size is within limit" do
      for i <- 1..3 do
        key = "ok#{i}"
        :ets.insert(@test_table, {key, %{}})
        Evictor.touch(@test_table, key)
      end

      Evictor.evict_table(@test_table, @ts_table, @ord_table, 5)

      assert :ets.info(@test_table, :size) == 3
    end
  end
end
