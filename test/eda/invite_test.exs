defmodule EDA.InviteTest do
  use ExUnit.Case, async: true

  alias EDA.Invite

  describe "from_raw/1" do
    test "parses with nested inviter and target_user" do
      raw = %{
        "code" => "abc123",
        "guild_id" => "g1",
        "channel_id" => "ch1",
        "inviter" => %{"id" => "u1", "username" => "alice"},
        "target_user" => %{"id" => "u2", "username" => "bob"},
        "max_age" => 3600,
        "max_uses" => 10,
        "uses" => 2,
        "temporary" => false
      }

      invite = Invite.from_raw(raw)
      assert %Invite{} = invite
      assert invite.code == "abc123"
      assert %EDA.User{id: "u1"} = invite.inviter
      assert %EDA.User{id: "u2"} = invite.target_user
    end

    test "handles nil users" do
      invite = Invite.from_raw(%{"code" => "abc"})
      assert invite.inviter == nil
      assert invite.target_user == nil
    end
  end
end
