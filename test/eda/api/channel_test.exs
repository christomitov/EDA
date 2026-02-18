defmodule EDA.API.ChannelTest do
  use ExUnit.Case

  alias EDA.API.Channel

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

  # ── get_channel ────────────────────────────────────────────────────

  describe "get/1" do
    test "GET /channels/:id", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/channels/111", fn conn ->
        json(conn, %{"id" => "111", "name" => "general"})
      end)

      assert {:ok, %{"name" => "general"}} = Channel.get("111")
    end
  end

  # ── modify_channel ─────────────────────────────────────────────────

  describe "modify/2" do
    test "PATCH /channels/:id", %{bypass: bypass} do
      Bypass.expect_once(bypass, "PATCH", "/channels/111", fn conn ->
        {body, conn} = read_json_body(conn)
        assert body["name"] == "renamed"
        json(conn, %{"id" => "111", "name" => "renamed"})
      end)

      assert {:ok, %{"name" => "renamed"}} = Channel.modify("111", %{name: "renamed"})
    end
  end

  # ── delete_channel ─────────────────────────────────────────────────

  describe "delete/1" do
    test "DELETE /channels/:id", %{bypass: bypass} do
      Bypass.expect_once(bypass, "DELETE", "/channels/111", fn conn ->
        json(conn, %{"id" => "111"})
      end)

      assert {:ok, %{"id" => "111"}} = Channel.delete("111")
    end
  end

  # ── create_guild_channel ───────────────────────────────────────────

  describe "create/2" do
    test "POST /guilds/:id/channels", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/guilds/111/channels", fn conn ->
        {body, conn} = read_json_body(conn)
        assert body["name"] == "new-channel"
        assert body["type"] == 0
        json(conn, %{"id" => "222", "name" => "new-channel"})
      end)

      assert {:ok, %{"name" => "new-channel"}} =
               Channel.create("111", %{name: "new-channel", type: 0})
    end
  end

  # ── modify_guild_channel_positions ─────────────────────────────────

  describe "modify_positions/2" do
    test "PATCH /guilds/:id/channels", %{bypass: bypass} do
      Bypass.expect_once(bypass, "PATCH", "/guilds/111/channels", fn conn ->
        Plug.Conn.resp(conn, 204, "")
      end)

      positions = [%{id: "222", position: 0}, %{id: "333", position: 1}]
      assert :ok = Channel.modify_positions("111", positions)
    end
  end

  # ── edit_channel_permissions ───────────────────────────────────────

  describe "edit_permissions/3" do
    test "PUT /channels/:id/permissions/:id", %{bypass: bypass} do
      Bypass.expect_once(bypass, "PUT", "/channels/111/permissions/222", fn conn ->
        {body, conn} = read_json_body(conn)
        assert body["allow"] == "1024"
        assert body["type"] == 0
        Plug.Conn.resp(conn, 204, "")
      end)

      assert :ok =
               Channel.edit_permissions("111", "222", %{allow: "1024", deny: "0", type: 0})
    end
  end

  # ── delete_channel_permissions ─────────────────────────────────────

  describe "delete_permissions/2" do
    test "DELETE /channels/:id/permissions/:id", %{bypass: bypass} do
      Bypass.expect_once(bypass, "DELETE", "/channels/111/permissions/222", fn conn ->
        Plug.Conn.resp(conn, 204, "")
      end)

      assert :ok = Channel.delete_permissions("111", "222")
    end
  end

  # ── trigger_typing ─────────────────────────────────────────────────

  describe "trigger_typing/1" do
    test "POST /channels/:id/typing", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/channels/111/typing", fn conn ->
        Plug.Conn.resp(conn, 204, "")
      end)

      assert :ok = Channel.trigger_typing("111")
    end
  end
end
