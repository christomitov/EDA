defmodule EDA.PresenceTest do
  use ExUnit.Case, async: true

  alias EDA.Presence

  describe "activity builders" do
    test "playing/1 returns type :playing" do
      assert Presence.playing("Elixir") == %{name: "Elixir", type: :playing}
    end

    test "streaming/2 returns type :streaming with url" do
      activity = Presence.streaming("on Twitch", "https://twitch.tv/example")
      assert activity == %{name: "on Twitch", type: :streaming, url: "https://twitch.tv/example"}
    end

    test "listening/1 returns type :listening" do
      assert Presence.listening("Spotify") == %{name: "Spotify", type: :listening}
    end

    test "watching/1 returns type :watching" do
      assert Presence.watching("you") == %{name: "you", type: :watching}
    end

    test "competing/1 returns type :competing" do
      assert Presence.competing("ranked") == %{name: "ranked", type: :competing}
    end

    test "custom/1 returns type :custom" do
      assert Presence.custom("vibing") == %{name: "vibing", type: :custom}
    end
  end

  describe "new/1" do
    test "builds struct with defaults" do
      presence = Presence.new()
      assert presence.status == :online
      assert presence.activities == []
      assert presence.afk == false
      assert presence.since == nil
    end

    test "builds struct with options" do
      presence =
        Presence.new(
          status: :dnd,
          activities: [Presence.watching("you")],
          afk: true,
          since: 1_000_000
        )

      assert presence.status == :dnd
      assert presence.activities == [%{name: "you", type: :watching}]
      assert presence.afk == true
      assert presence.since == 1_000_000
    end
  end

  describe "to_map/1" do
    test "serializes status as string" do
      presence = Presence.new(status: :dnd)
      result = Presence.to_map(presence)
      assert result.status == "dnd"
    end

    test "serializes activities with numeric type" do
      presence = Presence.new(activities: [Presence.playing("Elixir")])
      result = Presence.to_map(presence)

      assert result.activities == [%{name: "Elixir", type: 0}]
    end

    test "serializes streaming activity with url" do
      activity = Presence.streaming("live", "https://twitch.tv/ex")
      presence = Presence.new(activities: [activity])
      result = Presence.to_map(presence)

      assert result.activities == [%{name: "live", type: 1, url: "https://twitch.tv/ex"}]
    end

    test "serializes all fields" do
      presence =
        Presence.new(
          status: :idle,
          activities: [Presence.competing("ranked")],
          afk: true,
          since: 42
        )

      result = Presence.to_map(presence)

      assert result == %{
               status: "idle",
               activities: [%{name: "ranked", type: 5}],
               afk: true,
               since: 42
             }
    end

    test "all activity types map to correct numeric values" do
      assert Presence.activity_type_value(:playing) == 0
      assert Presence.activity_type_value(:streaming) == 1
      assert Presence.activity_type_value(:listening) == 2
      assert Presence.activity_type_value(:watching) == 3
      assert Presence.activity_type_value(:custom) == 4
      assert Presence.activity_type_value(:competing) == 5
    end
  end

  describe "status values" do
    test "online, idle, dnd, invisible are valid" do
      for status <- [:online, :idle, :dnd, :invisible] do
        presence = Presence.new(status: status)
        result = Presence.to_map(presence)
        assert result.status == to_string(status)
      end
    end
  end
end
