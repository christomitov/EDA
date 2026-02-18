defmodule EDA.SnowflakeTest do
  use ExUnit.Case, async: true

  alias EDA.Snowflake

  # Discord documented example: user ID 175928847299117063
  # Created: 2016-04-19T01:00:01.796Z
  # Snowflake 175928847299117063 → (175928847299117063 >>> 22) + discord_epoch
  @known_snowflake 175_928_847_299_117_063
  @known_snowflake_str "175928847299117063"
  @known_timestamp_ms 1_462_015_105_796

  describe "discord_epoch/0" do
    test "returns the Discord epoch" do
      assert Snowflake.discord_epoch() == 1_420_070_400_000
    end
  end

  describe "timestamp/1" do
    test "extracts timestamp from known snowflake (integer)" do
      assert Snowflake.timestamp(@known_snowflake) == @known_timestamp_ms
    end

    test "extracts timestamp from known snowflake (string)" do
      assert Snowflake.timestamp(@known_snowflake_str) == @known_timestamp_ms
    end

    test "snowflake 0 returns Discord epoch" do
      assert Snowflake.timestamp(0) == Snowflake.discord_epoch()
    end

    test "snowflake 0 as string returns Discord epoch" do
      assert Snowflake.timestamp("0") == Snowflake.discord_epoch()
    end
  end

  describe "created_at/1" do
    test "returns UTC DateTime for known snowflake (integer)" do
      dt = Snowflake.created_at(@known_snowflake)
      assert dt == ~U[2016-04-30 11:18:25.796Z]
      assert dt.time_zone == "Etc/UTC"
    end

    test "returns UTC DateTime for known snowflake (string)" do
      dt = Snowflake.created_at(@known_snowflake_str)
      assert dt == ~U[2016-04-30 11:18:25.796Z]
    end

    test "snowflake 0 returns Discord epoch as DateTime" do
      dt = Snowflake.created_at(0)
      assert dt == ~U[2015-01-01 00:00:00.000Z]
    end
  end

  describe "from_datetime/1" do
    test "produces a snowflake round-trippable with created_at/1" do
      dt = ~U[2024-01-01 00:00:00.000Z]
      snowflake = Snowflake.from_datetime(dt)
      assert Snowflake.created_at(snowflake) == dt
    end

    test "snowflake at Discord epoch is 0" do
      dt = ~U[2015-01-01 00:00:00.000Z]
      assert Snowflake.from_datetime(dt) == 0
    end

    test "generated snowflake preserves ordering" do
      dt1 = ~U[2023-06-01 00:00:00.000Z]
      dt2 = ~U[2023-07-01 00:00:00.000Z]
      assert Snowflake.from_datetime(dt1) < Snowflake.from_datetime(dt2)
    end
  end

  describe "age/1" do
    test "returns positive age for known snowflake (integer)" do
      assert Snowflake.age(@known_snowflake) > 0
    end

    test "returns positive age for known snowflake (string)" do
      assert Snowflake.age(@known_snowflake_str) > 0
    end

    test "age is a float" do
      assert is_float(Snowflake.age(@known_snowflake))
    end
  end
end
