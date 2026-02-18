defmodule EDA.Cache.PolicyTest do
  use ExUnit.Case, async: true

  alias EDA.Cache.Policy

  describe "check/4" do
    test ":all returns :cache" do
      assert Policy.check(:all, :guild, "123", %{}) == :cache
    end

    test "nil returns :cache (default)" do
      assert Policy.check(nil, :user, "456", %{}) == :cache
    end

    test ":none returns :skip" do
      assert Policy.check(:none, :presence, {"g1", "u1"}, %{}) == :skip
    end

    test "fn/3 returning :cache is respected" do
      fun = fn _entity, _key, _value -> :cache end
      assert Policy.check(fun, :member, {"g1", "u1"}, %{"nick" => "test"}) == :cache
    end

    test "fn/3 returning :skip is respected" do
      fun = fn _entity, _key, _value -> :skip end
      assert Policy.check(fun, :channel, {"g1", "c1"}, %{"type" => 4}) == :skip
    end

    test "fn/3 receives correct arguments" do
      fun = fn entity, key, value ->
        send(self(), {:policy_check, entity, key, value})
        :cache
      end

      value = %{"id" => "r1"}
      Policy.check(fun, :role, {"g1", "r1"}, value)

      assert_received {:policy_check, :role, {"g1", "r1"}, ^value}
    end

    test "module callback is invoked" do
      defmodule TestPolicy do
        @behaviour EDA.Cache.Policy
        @impl true
        def should_cache?(:guild, _key, %{"large" => true}), do: :skip
        def should_cache?(_entity, _key, _value), do: :cache
      end

      assert Policy.check(TestPolicy, :guild, "123", %{"large" => true}) == :skip
      assert Policy.check(TestPolicy, :guild, "456", %{"large" => false}) == :cache
    end

    test "module that raises propagates the error" do
      defmodule RaisingPolicy do
        @behaviour EDA.Cache.Policy
        @impl true
        def should_cache?(_e, _k, _v), do: raise("boom")
      end

      assert_raise RuntimeError, "boom", fn ->
        Policy.check(RaisingPolicy, :guild, "1", %{})
      end
    end
  end
end
