defmodule EDA.AuditLogTest do
  use ExUnit.Case, async: true

  alias EDA.AuditLog

  describe "action_name/1" do
    test "returns atom for known action type" do
      assert AuditLog.action_name(22) == :member_ban_add
      assert AuditLog.action_name(1) == :guild_update
      assert AuditLog.action_name(110) == :thread_create
    end

    test "returns :unknown for unrecognized type" do
      assert AuditLog.action_name(999) == :unknown
    end
  end

  describe "action_type/1" do
    test "returns integer for known atom" do
      assert AuditLog.action_type(:member_ban_add) == 22
      assert AuditLog.action_type(:guild_update) == 1
      assert AuditLog.action_type(:thread_create) == 110
    end

    test "returns nil for unknown atom" do
      assert AuditLog.action_type(:nonexistent) == nil
    end
  end

  describe "action_types/0" do
    test "returns the full map" do
      types = AuditLog.action_types()
      assert is_map(types)
      assert types[22] == :member_ban_add
      assert types[83] == :stage_instance_create
    end
  end

  describe "action_name/1 and action_type/1 roundtrip" do
    test "all known types roundtrip correctly" do
      for {int, atom} <- AuditLog.action_types() do
        assert AuditLog.action_name(int) == atom
        assert AuditLog.action_type(atom) == int
      end
    end
  end
end
