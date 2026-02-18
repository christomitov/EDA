defmodule EDA.API.InviteTest do
  use ExUnit.Case

  alias EDA.API.Invite

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

  # ── get_channel_invites ────────────────────────────────────────────

  describe "list_channel/1" do
    test "GET /channels/:id/invites", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/channels/111/invites", fn conn ->
        json(conn, [%{"code" => "xyz"}])
      end)

      assert {:ok, [%{"code" => "xyz"}]} = Invite.list_channel("111")
    end
  end

  # ── create_channel_invite ──────────────────────────────────────────

  describe "create/2" do
    test "POST /channels/:id/invites", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/channels/111/invites", fn conn ->
        {body, conn} = read_json_body(conn)
        assert body["max_age"] == 3600
        assert body["max_uses"] == 10
        json(conn, %{"code" => "abc"})
      end)

      assert {:ok, %{"code" => "abc"}} =
               Invite.create("111", max_age: 3600, max_uses: 10)
    end
  end

  # ── delete_invite ──────────────────────────────────────────────────

  describe "delete/1" do
    test "DELETE /invites/:code", %{bypass: bypass} do
      Bypass.expect_once(bypass, "DELETE", "/invites/abc123", fn conn ->
        json(conn, %{"code" => "abc123"})
      end)

      assert {:ok, %{"code" => "abc123"}} = Invite.delete("abc123")
    end
  end
end
