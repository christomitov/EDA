defmodule EDA.Sticker.PackTest do
  use ExUnit.Case, async: true

  alias EDA.Sticker
  alias EDA.Sticker.Pack

  describe "from_raw/1" do
    test "parses all fields and stickers into structs" do
      raw = %{
        "id" => "p1",
        "name" => "Wumpus Beyond",
        "sku_id" => "sku1",
        "cover_sticker_id" => "cs1",
        "description" => "Wumpus stickers",
        "banner_asset_id" => "banner1",
        "stickers" => [
          %{"id" => "s1", "name" => "wave", "type" => 1, "format_type" => 1},
          %{"id" => "s2", "name" => "dance", "type" => 1, "format_type" => 4}
        ]
      }

      pack = Pack.from_raw(raw)
      assert %Pack{} = pack
      assert pack.id == "p1"
      assert pack.name == "Wumpus Beyond"
      assert pack.sku_id == "sku1"
      assert pack.cover_sticker_id == "cs1"
      assert pack.description == "Wumpus stickers"
      assert pack.banner_asset_id == "banner1"
      assert length(pack.stickers) == 2
      assert [%Sticker{name: "wave"}, %Sticker{name: "dance"}] = pack.stickers
    end

    test "handles missing stickers key" do
      pack = Pack.from_raw(%{"id" => "p1", "name" => "Empty"})
      assert pack.stickers == []
    end

    test "handles empty stickers list" do
      pack = Pack.from_raw(%{"id" => "p1", "stickers" => []})
      assert pack.stickers == []
    end
  end

  describe "banner_url/1" do
    test "returns CDN URL when banner_asset_id is present" do
      pack = %Pack{id: "p1", banner_asset_id: "abc123"}
      url = Pack.banner_url(pack)
      assert url == "https://cdn.discordapp.com/app-assets/710982414301790216/store/abc123.png"
    end

    test "returns nil when banner_asset_id is nil" do
      assert Pack.banner_url(%Pack{id: "p1", banner_asset_id: nil}) == nil
    end
  end
end
