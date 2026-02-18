defmodule EDA.Event.GuildStickersUpdateTest do
  use ExUnit.Case, async: true

  alias EDA.Event
  alias EDA.Event.GuildStickersUpdate
  alias EDA.Sticker

  describe "from_raw/1" do
    test "parses guild_id and stickers into structs" do
      raw = %{
        "guild_id" => "g1",
        "stickers" => [
          %{"id" => "s1", "name" => "wave", "type" => 2, "format_type" => 1},
          %{"id" => "s2", "name" => "dance", "type" => 2, "format_type" => 4}
        ]
      }

      event = GuildStickersUpdate.from_raw(raw)
      assert %GuildStickersUpdate{} = event
      assert event.guild_id == "g1"
      assert length(event.stickers) == 2

      assert [%Sticker{name: "wave", type: :guild}, %Sticker{name: "dance", format_type: :gif}] =
               event.stickers
    end

    test "handles missing stickers key" do
      event = GuildStickersUpdate.from_raw(%{"guild_id" => "g1"})
      assert event.stickers == []
    end
  end

  describe "Event.from_raw/2 routing" do
    test "GUILD_STICKERS_UPDATE routes to GuildStickersUpdate" do
      data = %{
        "guild_id" => "g1",
        "stickers" => [%{"id" => "s1", "name" => "test", "type" => 2, "format_type" => 1}]
      }

      result = Event.from_raw("GUILD_STICKERS_UPDATE", data)
      assert %GuildStickersUpdate{} = result
      assert result.guild_id == "g1"
    end
  end
end
