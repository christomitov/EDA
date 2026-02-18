defmodule EDA.ReactionTest do
  use ExUnit.Case, async: true

  alias EDA.Reaction

  describe "from_raw/1" do
    test "parses with nested emoji" do
      raw = %{
        "count" => 5,
        "me" => true,
        "emoji" => %{"id" => "e1", "name" => "fire"}
      }

      reaction = Reaction.from_raw(raw)
      assert %Reaction{} = reaction
      assert reaction.count == 5
      assert reaction.me == true
      assert %EDA.Emoji{id: "e1", name: "fire"} = reaction.emoji
    end

    test "handles nil emoji" do
      reaction = Reaction.from_raw(%{"count" => 1})
      assert reaction.emoji == nil
    end
  end
end
