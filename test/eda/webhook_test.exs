defmodule EDA.WebhookTest do
  use ExUnit.Case, async: true

  alias EDA.Webhook

  describe "from_raw/1" do
    test "parses with nested user" do
      raw = %{
        "id" => "wh1",
        "type" => 1,
        "guild_id" => "g1",
        "channel_id" => "ch1",
        "user" => %{"id" => "u1", "username" => "alice"},
        "name" => "My Webhook",
        "token" => "tok123"
      }

      wh = Webhook.from_raw(raw)
      assert %Webhook{} = wh
      assert wh.id == "wh1"
      assert %EDA.User{id: "u1"} = wh.user
    end

    test "handles nil user" do
      wh = Webhook.from_raw(%{"id" => "wh1"})
      assert wh.user == nil
    end
  end
end
