defmodule EDA.ForumTagTest do
  use ExUnit.Case, async: true

  alias EDA.ForumTag

  describe "from_raw/1" do
    test "parses all fields" do
      raw = %{
        "id" => "111",
        "name" => "Bug",
        "moderated" => true,
        "emoji_id" => "222",
        "emoji_name" => nil
      }

      tag = ForumTag.from_raw(raw)
      assert %ForumTag{} = tag
      assert tag.id == "111"
      assert tag.name == "Bug"
      assert tag.moderated == true
      assert tag.emoji_id == "222"
      assert tag.emoji_name == nil
    end

    test "parses with unicode emoji" do
      raw = %{
        "id" => "111",
        "name" => "Resolved",
        "moderated" => false,
        "emoji_id" => nil,
        "emoji_name" => "✅"
      }

      tag = ForumTag.from_raw(raw)
      assert tag.emoji_name == "✅"
      assert tag.emoji_id == nil
    end

    test "parses with custom emoji" do
      raw = %{
        "id" => "111",
        "name" => "Cool",
        "moderated" => false,
        "emoji_id" => "999",
        "emoji_name" => nil
      }

      tag = ForumTag.from_raw(raw)
      assert tag.emoji_id == "999"
      assert tag.emoji_name == nil
    end

    test "parses without emoji" do
      raw = %{
        "id" => "111",
        "name" => "Plain",
        "moderated" => false,
        "emoji_id" => nil,
        "emoji_name" => nil
      }

      tag = ForumTag.from_raw(raw)
      assert tag.emoji_id == nil
      assert tag.emoji_name == nil
    end

    test "defaults moderated to false when nil" do
      raw = %{"id" => "1", "name" => "Tag", "moderated" => nil}
      tag = ForumTag.from_raw(raw)
      assert tag.moderated == false
    end
  end

  describe "to_raw/1" do
    test "roundtrip preserves data" do
      raw = %{
        "id" => "111",
        "name" => "Bug",
        "moderated" => true,
        "emoji_id" => "222",
        "emoji_name" => nil
      }

      tag = ForumTag.from_raw(raw)
      result = ForumTag.to_raw(tag)

      assert result["id"] == "111"
      assert result["name"] == "Bug"
      assert result["moderated"] == true
      assert result["emoji_id"] == "222"
    end

    test "omits nil values" do
      tag = %ForumTag{name: "Simple", moderated: false}
      result = ForumTag.to_raw(tag)

      assert result == %{"name" => "Simple", "moderated" => false}
      refute Map.has_key?(result, "id")
      refute Map.has_key?(result, "emoji_id")
      refute Map.has_key?(result, "emoji_name")
    end
  end

  describe "new/2" do
    test "creates a tag with name only" do
      tag = ForumTag.new("Help")
      assert tag.name == "Help"
      assert tag.moderated == false
      assert tag.id == nil
      assert tag.emoji_id == nil
      assert tag.emoji_name == nil
    end

    test "creates a tag with moderated flag" do
      tag = ForumTag.new("Admin Only", moderated: true)
      assert tag.moderated == true
    end

    test "creates a tag with unicode emoji string" do
      tag = ForumTag.new("Bug", emoji: "🐛")
      assert tag.emoji_name == "🐛"
      assert tag.emoji_id == nil
    end

    test "creates a tag with Emoji struct" do
      emoji = %EDA.Emoji{id: "99", name: "cool"}
      tag = ForumTag.new("Cool", emoji: emoji)
      assert tag.emoji_id == "99"
      assert tag.emoji_name == "cool"
    end
  end
end
