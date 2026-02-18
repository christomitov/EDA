defmodule EDA.EmojiTest do
  use ExUnit.Case, async: true

  alias EDA.Emoji

  describe "from_raw/1" do
    test "parses a custom emoji" do
      raw = %{
        "id" => "123456",
        "name" => "cool",
        "animated" => true,
        "roles" => ["r1", "r2"],
        "user" => %{"id" => "u1"},
        "require_colons" => true,
        "managed" => false,
        "available" => true
      }

      emoji = Emoji.from_raw(raw)
      assert %Emoji{} = emoji
      assert emoji.id == "123456"
      assert emoji.name == "cool"
      assert emoji.animated == true
      assert emoji.roles == ["r1", "r2"]
      assert emoji.user == %EDA.User{id: "u1"}
      assert emoji.require_colons == true
      assert emoji.managed == false
      assert emoji.available == true
    end

    test "parses a unicode emoji" do
      raw = %{"id" => nil, "name" => "👍"}
      emoji = Emoji.from_raw(raw)
      assert emoji.id == nil
      assert emoji.name == "👍"
    end

    test "handles missing optional fields" do
      raw = %{"id" => "123", "name" => "test"}
      emoji = Emoji.from_raw(raw)
      assert emoji.animated == nil
      assert emoji.roles == nil
    end
  end

  describe "custom?/1" do
    test "returns true for custom emoji" do
      assert Emoji.custom?(%Emoji{id: "123", name: "cool"})
    end

    test "returns false for unicode emoji" do
      refute Emoji.custom?(%Emoji{id: nil, name: "👍"})
    end
  end

  describe "unicode?/1" do
    test "returns true for unicode emoji" do
      assert Emoji.unicode?(%Emoji{id: nil, name: "👍"})
    end

    test "returns false for custom emoji" do
      refute Emoji.unicode?(%Emoji{id: "123", name: "cool"})
    end
  end

  describe "api_name/1" do
    test "unicode emoji returns just the name" do
      assert Emoji.api_name(%Emoji{id: nil, name: "👍"}) == "👍"
    end

    test "custom emoji returns name:id" do
      assert Emoji.api_name(%Emoji{id: "123", name: "cool"}) == "cool:123"
    end
  end

  describe "mention/1" do
    test "unicode emoji returns just the name" do
      assert Emoji.mention(%Emoji{id: nil, name: "👍"}) == "👍"
    end

    test "static custom emoji returns <:name:id>" do
      assert Emoji.mention(%Emoji{id: "123", name: "cool", animated: false}) == "<:cool:123>"
    end

    test "animated custom emoji returns <a:name:id>" do
      assert Emoji.mention(%Emoji{id: "123", name: "cool", animated: true}) == "<a:cool:123>"
    end

    test "custom emoji with nil animated returns <:name:id>" do
      assert Emoji.mention(%Emoji{id: "123", name: "cool", animated: nil}) == "<:cool:123>"
    end
  end

  describe "image_url/1" do
    test "returns nil for unicode emoji" do
      assert Emoji.image_url(%Emoji{id: nil, name: "👍"}) == nil
    end

    test "returns .gif URL for animated emoji" do
      url = Emoji.image_url(%Emoji{id: "123", name: "cool", animated: true})
      assert url == "https://cdn.discordapp.com/emojis/123.gif"
    end

    test "returns .png URL for static custom emoji" do
      url = Emoji.image_url(%Emoji{id: "123", name: "cool", animated: false})
      assert url == "https://cdn.discordapp.com/emojis/123.png"
    end

    test "returns .png URL when animated is nil" do
      url = Emoji.image_url(%Emoji{id: "123", name: "cool"})
      assert url == "https://cdn.discordapp.com/emojis/123.png"
    end
  end

  describe "String.Chars" do
    test "to_string returns mention for custom emoji" do
      emoji = %Emoji{id: "123", name: "cool", animated: false}
      assert to_string(emoji) == "<:cool:123>"
    end

    test "to_string returns name for unicode emoji" do
      emoji = %Emoji{id: nil, name: "👍"}
      assert to_string(emoji) == "👍"
    end

    test "interpolation works" do
      emoji = %Emoji{id: "123", name: "cool", animated: true}
      assert "Hello #{emoji}" == "Hello <a:cool:123>"
    end
  end
end
