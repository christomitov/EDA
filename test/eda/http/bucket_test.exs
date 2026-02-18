defmodule EDA.HTTP.BucketTest do
  use ExUnit.Case, async: true

  alias EDA.HTTP.Bucket

  describe "key/2" do
    test "guild routes preserve guild_id" do
      assert Bucket.key(:get, "/guilds/123456789012345678/bans") ==
               "/guilds/123456789012345678/bans"
    end

    test "guild routes replace non-major snowflakes" do
      assert Bucket.key(:get, "/guilds/123456789012345678/bans/987654321012345678") ==
               "/guilds/123456789012345678/bans/:id"
    end

    test "channel routes preserve channel_id" do
      assert Bucket.key(:post, "/channels/123456789012345678/messages") ==
               "/channels/123456789012345678/messages"
    end

    test "channel routes replace message snowflake" do
      assert Bucket.key(:get, "/channels/123456789012345678/messages/987654321012345678") ==
               "/channels/123456789012345678/messages/:id"
    end

    test "webhook routes preserve webhook_id" do
      assert Bucket.key(:post, "/webhooks/123456789012345678/token") ==
               "/webhooks/123456789012345678/token"
    end

    test "DELETE on messages gets prefix" do
      assert Bucket.key(:delete, "/channels/123456789012345678/messages/987654321012345678") ==
               "DELETE:/channels/123456789012345678/messages/:id"
    end

    test "non-DELETE on messages has no prefix" do
      assert Bucket.key(:get, "/channels/123456789012345678/messages/987654321012345678") ==
               "/channels/123456789012345678/messages/:id"
    end

    test "different guilds produce different bucket keys" do
      key1 = Bucket.key(:get, "/guilds/111111111111111111/bans")
      key2 = Bucket.key(:get, "/guilds/222222222222222222/bans")
      assert key1 != key2
    end

    test "different channels produce different bucket keys" do
      key1 = Bucket.key(:post, "/channels/111111111111111111/messages")
      key2 = Bucket.key(:post, "/channels/222222222222222222/messages")
      assert key1 != key2
    end

    test "strips query string" do
      assert Bucket.key(:get, "/channels/123456789012345678/messages?limit=50") ==
               "/channels/123456789012345678/messages"
    end
  end
end
