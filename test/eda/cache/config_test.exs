defmodule EDA.Cache.ConfigTest do
  use ExUnit.Case

  alias EDA.Cache.Config

  setup do
    # Clean up persistent_term between tests
    for key <- Config.cache_keys() do
      :persistent_term.erase({:eda_cache_config, key})
    end

    on_exit(fn ->
      Application.delete_env(:eda, :cache)
      Config.setup()
    end)
  end

  describe "setup/0" do
    test "defaults when no config is set" do
      Application.delete_env(:eda, :cache)
      Config.setup()

      assert Config.policy(:guilds) == :all
      assert Config.max_size(:guilds) == nil
      assert Config.policy(:users) == :all
    end

    test "partial config only affects specified caches" do
      Application.put_env(:eda, :cache, members: [policy: :none])
      Config.setup()

      assert Config.policy(:members) == :none
      assert Config.policy(:guilds) == :all
      assert Config.policy(:users) == :all
    end

    test "policy/1 returns configured policy" do
      fun = fn _e, _k, _v -> :skip end
      Application.put_env(:eda, :cache, channels: [policy: fun])
      Config.setup()

      assert Config.policy(:channels) == fun
    end

    test "max_size/1 returns configured value" do
      Application.put_env(:eda, :cache, users: [max_size: 50_000])
      Config.setup()

      assert Config.max_size(:users) == 50_000
    end

    test "max_size/1 returns nil when not configured" do
      Application.put_env(:eda, :cache, guilds: [])
      Config.setup()

      assert Config.max_size(:guilds) == nil
    end

    test "setup/0 is idempotent" do
      Application.put_env(:eda, :cache, presences: [policy: :none])
      Config.setup()
      Config.setup()

      assert Config.policy(:presences) == :none
    end
  end
end
