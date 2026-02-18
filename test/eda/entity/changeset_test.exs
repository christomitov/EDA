defmodule EDA.Entity.ChangesetTest do
  use ExUnit.Case, async: true

  alias EDA.Entity.Changeset

  defp sample_guild do
    EDA.Guild.from_raw(%{"id" => "g1", "name" => "Test"})
  end

  describe "new/2" do
    test "creates an empty changeset" do
      cs = Changeset.new(sample_guild(), EDA.Guild)
      assert %Changeset{} = cs
      assert cs.entity == sample_guild()
      assert cs.module == EDA.Guild
      assert cs.changes == %{}
    end
  end

  describe "put/3" do
    test "accumulates changes" do
      cs =
        Changeset.new(sample_guild(), EDA.Guild)
        |> Changeset.put(:name, "New Name")
        |> Changeset.put(:icon, "new_icon")

      assert cs.changes == %{name: "New Name", icon: "new_icon"}
    end

    test "overwrites same key" do
      cs =
        Changeset.new(sample_guild(), EDA.Guild)
        |> Changeset.put(:name, "First")
        |> Changeset.put(:name, "Second")

      assert cs.changes == %{name: "Second"}
    end
  end

  describe "changed?/1" do
    test "returns false when empty" do
      cs = Changeset.new(sample_guild(), EDA.Guild)
      refute Changeset.changed?(cs)
    end

    test "returns true after put" do
      cs =
        Changeset.new(sample_guild(), EDA.Guild)
        |> Changeset.put(:name, "New")

      assert Changeset.changed?(cs)
    end
  end

  describe "changes/1" do
    test "returns the accumulated changes map" do
      cs =
        Changeset.new(sample_guild(), EDA.Guild)
        |> Changeset.put(:name, "New")
        |> Changeset.put(:icon, "abc")

      assert Changeset.changes(cs) == %{name: "New", icon: "abc"}
    end
  end
end
