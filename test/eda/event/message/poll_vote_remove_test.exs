defmodule EDA.Event.MessagePollVoteRemoveTest do
  use ExUnit.Case, async: true

  alias EDA.Event.MessagePollVoteRemove

  describe "from_raw/1" do
    test "parses all fields" do
      raw = %{
        "user_id" => "u1",
        "channel_id" => "ch1",
        "message_id" => "msg1",
        "guild_id" => "g1",
        "answer_id" => 3
      }

      event = MessagePollVoteRemove.from_raw(raw)
      assert %MessagePollVoteRemove{} = event
      assert event.user_id == "u1"
      assert event.channel_id == "ch1"
      assert event.message_id == "msg1"
      assert event.guild_id == "g1"
      assert event.answer_id == 3
    end
  end
end
