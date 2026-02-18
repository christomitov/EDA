defmodule EDA.AuditLog.ChangeTest do
  use ExUnit.Case, async: true

  alias EDA.AuditLog.Change

  describe "from_raw/1" do
    test "parses all fields" do
      raw = %{"key" => "name", "old_value" => "old", "new_value" => "new"}
      change = Change.from_raw(raw)

      assert %Change{} = change
      assert change.key == "name"
      assert change.old_value == "old"
      assert change.new_value == "new"
    end

    test "handles nil values" do
      raw = %{"key" => "color", "new_value" => 0xFF0000}
      change = Change.from_raw(raw)

      assert change.key == "color"
      assert change.old_value == nil
      assert change.new_value == 0xFF0000
    end

    test "supports Access protocol" do
      change = Change.from_raw(%{"key" => "topic"})
      assert change[:key] == "topic"
      assert change["key"] == "topic"
    end
  end
end
