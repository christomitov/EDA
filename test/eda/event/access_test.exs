defmodule EDA.Event.AccessTest do
  use ExUnit.Case, async: true

  alias EDA.Event.MessageCreate

  defp sample_msg do
    MessageCreate.from_raw(%{
      "id" => "123",
      "channel_id" => "456",
      "content" => "hello world",
      "author" => %{"id" => "789", "username" => "testuser"}
    })
  end

  describe "fetch/2" do
    test "atom key access works" do
      msg = sample_msg()
      assert {:ok, "hello world"} = Access.fetch(msg, :content)
    end

    test "string key access works" do
      msg = sample_msg()
      assert {:ok, "hello world"} = Access.fetch(msg, "content")
    end

    test "string key returns :error for nonexistent field" do
      msg = sample_msg()
      assert :error = Access.fetch(msg, "nonexistent_field_xyz")
    end

    test "atom key returns :error for nonexistent field" do
      msg = sample_msg()
      assert :error = Access.fetch(msg, :nonexistent_field_xyz)
    end
  end

  describe "bracket access" do
    test "struct[:field] works" do
      msg = sample_msg()
      assert msg[:content] == "hello world"
    end

    test "struct[\"field\"] works" do
      msg = sample_msg()
      assert msg["content"] == "hello world"
    end

    test "nil for missing string key" do
      msg = sample_msg()
      assert msg["no_such_key_xyz"] == nil
    end
  end

  describe "dot access" do
    test "struct.field works" do
      msg = sample_msg()
      assert msg.content == "hello world"
      assert msg.id == "123"
    end
  end

  describe "get_in/2" do
    test "works with atom keys" do
      msg = sample_msg()
      assert get_in(msg, [:content]) == "hello world"
    end

    test "works with string keys" do
      msg = sample_msg()
      assert get_in(msg, ["content"]) == "hello world"
    end

    test "works with mixed keys into nested structs" do
      msg = sample_msg()
      assert get_in(msg, [:author]) == %EDA.User{id: "789", username: "testuser"}
    end
  end

  describe "get_and_update/3" do
    test "works with atom key" do
      msg = sample_msg()

      {old, updated} =
        Access.get_and_update(msg, :content, fn val -> {val, "updated"} end)

      assert old == "hello world"
      assert updated.content == "updated"
    end

    test "works with string key" do
      msg = sample_msg()

      {old, updated} =
        Access.get_and_update(msg, "content", fn val -> {val, "updated"} end)

      assert old == "hello world"
      assert updated.content == "updated"
    end
  end

  describe "pop/2" do
    test "works with atom key" do
      msg = sample_msg()
      {val, rest} = Access.pop(msg, :content)
      assert val == "hello world"
      assert rest[:content] == nil
    end

    test "works with string key" do
      msg = sample_msg()
      {val, rest} = Access.pop(msg, "content")
      assert val == "hello world"
      assert rest[:content] == nil
    end
  end
end
