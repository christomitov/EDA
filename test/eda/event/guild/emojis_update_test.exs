defmodule EDA.Event.GuildEmojisUpdateTest do
  use ExUnit.Case, async: true

  alias EDA.Event
  alias EDA.Event.GuildEmojisUpdate
  alias EDA.Emoji

  describe "from_raw/1" do
    test "parses guild_id and emojis into structs" do
      raw = %{
        "guild_id" => "g1",
        "emojis" => [
          %{"id" => "e1", "name" => "cool", "animated" => false},
          %{"id" => nil, "name" => "👍"}
        ]
      }

      event = GuildEmojisUpdate.from_raw(raw)
      assert %GuildEmojisUpdate{} = event
      assert event.guild_id == "g1"
      assert length(event.emojis) == 2
      assert [%Emoji{id: "e1", name: "cool"}, %Emoji{id: nil, name: "👍"}] = event.emojis
    end

    test "handles missing emojis key" do
      event = GuildEmojisUpdate.from_raw(%{"guild_id" => "g1"})
      assert event.emojis == []
    end
  end

  describe "Event.from_raw/2 routing" do
    test "GUILD_EMOJIS_UPDATE routes to GuildEmojisUpdate" do
      data = %{
        "guild_id" => "g1",
        "emojis" => [%{"id" => "e1", "name" => "test"}]
      }

      result = Event.from_raw("GUILD_EMOJIS_UPDATE", data)
      assert %GuildEmojisUpdate{} = result
      assert result.guild_id == "g1"
    end
  end
end
