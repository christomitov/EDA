defmodule EDA.VoiceStateTest do
  use ExUnit.Case, async: true

  alias EDA.VoiceState

  describe "from_raw/1" do
    test "parses with nested member" do
      raw = %{
        "guild_id" => "g1",
        "channel_id" => "vc1",
        "user_id" => "u1",
        "member" => %{"user" => %{"id" => "u1", "username" => "alice"}, "nick" => "ali"},
        "self_mute" => true,
        "self_deaf" => false
      }

      vs = VoiceState.from_raw(raw)
      assert %VoiceState{} = vs
      assert vs.guild_id == "g1"
      assert %EDA.Member{nick: "ali"} = vs.member
      assert %EDA.User{id: "u1"} = vs.member.user
    end

    test "handles nil member" do
      vs = VoiceState.from_raw(%{"guild_id" => "g1", "user_id" => "u1"})
      assert vs.member == nil
    end
  end
end
