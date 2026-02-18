defmodule EDA.API.UserTest do
  use ExUnit.Case

  alias EDA.API.User

  setup do
    bypass = Bypass.open()
    Application.put_env(:eda, :base_url, "http://localhost:#{bypass.port}")
    Application.put_env(:eda, :token, "test-token")

    on_exit(fn ->
      Application.delete_env(:eda, :base_url)
    end)

    {:ok, bypass: bypass}
  end

  # ── Helpers ──────────────────────────────────────────────────────────

  defp json(conn, body, status \\ 200) do
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.resp(status, Jason.encode!(body))
  end

  defp read_json_body(conn) do
    {:ok, raw, conn} = Plug.Conn.read_body(conn)
    {Jason.decode!(raw), conn}
  end

  # ── get_current_user ───────────────────────────────────────────────

  describe "me/0" do
    test "GET /users/@me", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/users/@me", fn conn ->
        json(conn, %{"id" => "1", "username" => "bot"})
      end)

      assert {:ok, %{"username" => "bot"}} = User.me()
    end
  end

  # ── modify_current_user ────────────────────────────────────────────

  describe "modify_me/1" do
    test "PATCH /users/@me", %{bypass: bypass} do
      Bypass.expect_once(bypass, "PATCH", "/users/@me", fn conn ->
        {body, conn} = read_json_body(conn)
        assert body["username"] == "new-name"
        json(conn, %{"id" => "1", "username" => "new-name"})
      end)

      assert {:ok, %{"username" => "new-name"}} =
               User.modify_me(%{username: "new-name"})
    end
  end

  # ── get_user ───────────────────────────────────────────────────────

  describe "get/1" do
    test "GET /users/:id", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/users/222", fn conn ->
        json(conn, %{"id" => "222", "username" => "user"})
      end)

      assert {:ok, %{"username" => "user"}} = User.get("222")
    end
  end

  # ── create_dm ──────────────────────────────────────────────────────

  describe "create_dm/1" do
    test "POST /users/@me/channels", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/users/@me/channels", fn conn ->
        {body, conn} = read_json_body(conn)
        assert body["recipient_id"] == "222"
        json(conn, %{"id" => "999", "type" => 1})
      end)

      assert {:ok, %{"type" => 1}} = User.create_dm("222")
    end
  end
end
