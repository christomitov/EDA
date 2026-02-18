defmodule EDA.MemberTest do
  use ExUnit.Case

  alias EDA.Member

  describe "from_raw/1" do
    test "parses with nested user" do
      raw = %{
        "user" => %{"id" => "u1", "username" => "alice"},
        "nick" => "ali",
        "roles" => ["r1", "r2"],
        "joined_at" => "2025-01-01T00:00:00Z",
        "deaf" => false,
        "mute" => false
      }

      member = Member.from_raw(raw)
      assert %Member{} = member
      assert %EDA.User{id: "u1", username: "alice"} = member.user
      assert member.nick == "ali"
      assert member.roles == ["r1", "r2"]
    end

    test "handles nil user" do
      member = Member.from_raw(%{"nick" => "ali"})
      assert member.user == nil
    end
  end

  describe "Access behaviour" do
    test "string key access on nested user" do
      member = Member.from_raw(%{"user" => %{"id" => "u1", "username" => "alice"}})
      assert member["user"]["username"] == "alice"
    end
  end

  # ── Entity Manager ──

  setup do
    bypass = Bypass.open()
    Application.put_env(:eda, :base_url, "http://localhost:#{bypass.port}")
    Application.put_env(:eda, :token, "test-token")

    on_exit(fn ->
      Application.delete_env(:eda, :base_url)
    end)

    {:ok, bypass: bypass}
  end

  defp json(conn, body) do
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.resp(200, Jason.encode!(body))
  end

  describe "fetch_member/2" do
    test "returns a Member struct from REST", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/guilds/g1/members/u1", fn conn ->
        json(conn, %{"user" => %{"id" => "u1", "username" => "alice"}, "nick" => "ali"})
      end)

      assert {:ok, %Member{nick: "ali"}} = Member.fetch_member("g1", "u1")
    end
  end

  describe "modify/4" do
    test "returns a Member struct", %{bypass: bypass} do
      Bypass.expect_once(bypass, "PATCH", "/guilds/g1/members/u1", fn conn ->
        json(conn, %{"user" => %{"id" => "u1"}, "nick" => "new_nick"})
      end)

      assert {:ok, %Member{nick: "new_nick"}} =
               Member.modify("g1", "u1", %{nick: "new_nick"})
    end
  end

  describe "kick/3" do
    test "kicks a member", %{bypass: bypass} do
      Bypass.expect_once(bypass, "DELETE", "/guilds/g1/members/u1", fn conn ->
        Plug.Conn.resp(conn, 204, "")
      end)

      assert :ok = Member.kick("g1", "u1")
    end
  end

  describe "add_role/4 and remove_role/4" do
    test "adds a role", %{bypass: bypass} do
      Bypass.expect_once(bypass, "PUT", "/guilds/g1/members/u1/roles/r1", fn conn ->
        Plug.Conn.resp(conn, 204, "")
      end)

      assert :ok = Member.add_role("g1", "u1", "r1")
    end

    test "removes a role", %{bypass: bypass} do
      Bypass.expect_once(bypass, "DELETE", "/guilds/g1/members/u1/roles/r1", fn conn ->
        Plug.Conn.resp(conn, 204, "")
      end)

      assert :ok = Member.remove_role("g1", "u1", "r1")
    end
  end
end
