defmodule EDA.API.BanTest do
  use ExUnit.Case

  alias EDA.API.Ban

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

  # ── get_guild_bans ─────────────────────────────────────────────────

  describe "list/2" do
    test "GET /guilds/:id/bans", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/guilds/111/bans", fn conn ->
        json(conn, [%{"user" => %{"id" => "222"}, "reason" => "spam"}])
      end)

      assert {:ok, [%{"reason" => "spam"}]} = Ban.list("111")
    end

    test "with pagination opts", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/guilds/111/bans", fn conn ->
        conn = Plug.Conn.fetch_query_params(conn)
        assert conn.query_params["limit"] == "5"
        json(conn, [])
      end)

      assert {:ok, []} = Ban.list("111", limit: 5)
    end
  end

  # ── get_guild_ban ──────────────────────────────────────────────────

  describe "get/2" do
    test "GET /guilds/:id/bans/:id", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/guilds/111/bans/222", fn conn ->
        json(conn, %{"user" => %{"id" => "222"}, "reason" => "spam"})
      end)

      assert {:ok, %{"reason" => "spam"}} = Ban.get("111", "222")
    end
  end

  # ── create_guild_ban ───────────────────────────────────────────────

  describe "create/3" do
    test "PUT /guilds/:id/bans/:id", %{bypass: bypass} do
      Bypass.expect_once(bypass, "PUT", "/guilds/111/bans/222", fn conn ->
        {body, conn} = read_json_body(conn)
        assert body["delete_message_seconds"] == 86_400
        Plug.Conn.resp(conn, 204, "")
      end)

      assert :ok = Ban.create("111", "222", delete_message_seconds: 86_400)
    end

    test "without opts", %{bypass: bypass} do
      Bypass.expect_once(bypass, "PUT", "/guilds/111/bans/222", fn conn ->
        {body, conn} = read_json_body(conn)
        assert body == %{}
        Plug.Conn.resp(conn, 204, "")
      end)

      assert :ok = Ban.create("111", "222")
    end
  end

  # ── remove_guild_ban ───────────────────────────────────────────────

  describe "remove/2" do
    test "DELETE /guilds/:id/bans/:id", %{bypass: bypass} do
      Bypass.expect_once(bypass, "DELETE", "/guilds/111/bans/222", fn conn ->
        Plug.Conn.resp(conn, 204, "")
      end)

      assert :ok = Ban.remove("111", "222")
    end
  end

  # ── bulk_guild_ban ─────────────────────────────────────────────────

  describe "bulk/3" do
    test "POST /guilds/:id/bulk-ban with user_ids", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/guilds/111/bulk-ban", fn conn ->
        {body, conn} = read_json_body(conn)
        assert body["user_ids"] == ["222", "333"]

        json(conn, %{
          "banned_users" => ["222", "333"],
          "failed_users" => []
        })
      end)

      assert {:ok, %{"banned_users" => ["222", "333"]}} =
               Ban.bulk("111", ["222", "333"])
    end

    test "with delete_message_seconds option", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/guilds/111/bulk-ban", fn conn ->
        {body, conn} = read_json_body(conn)
        assert body["user_ids"] == ["222"]
        assert body["delete_message_seconds"] == 86_400
        json(conn, %{"banned_users" => ["222"], "failed_users" => []})
      end)

      assert {:ok, _} =
               Ban.bulk("111", ["222"], delete_message_seconds: 86_400)
    end

    test "rejects more than 200 user_ids" do
      user_ids = Enum.map(1..201, &to_string/1)
      assert {:error, :too_many_users} = Ban.bulk("111", user_ids)
    end

    test "empty list succeeds", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/guilds/111/bulk-ban", fn conn ->
        {body, conn} = read_json_body(conn)
        assert body["user_ids"] == []
        json(conn, %{"banned_users" => [], "failed_users" => []})
      end)

      assert {:ok, _} = Ban.bulk("111", [])
    end

    test "403 error", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/guilds/111/bulk-ban", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(
          403,
          Jason.encode!(%{"message" => "Missing Permissions", "code" => 50_013})
        )
      end)

      assert {:error, %{status: 403, message: "Missing Permissions"}} =
               Ban.bulk("111", ["222"])
    end
  end

  # ── stream ───────────────────────────────────────────────────────────

  describe "stream/2" do
    test "paginates two pages and stops on empty", %{bypass: bypass} do
      call_count = :counters.new(1, [])

      Bypass.expect(bypass, "GET", "/guilds/111/bans", fn conn ->
        :counters.add(call_count, 1, 1)
        conn = Plug.Conn.fetch_query_params(conn)

        case :counters.get(call_count, 1) do
          1 ->
            assert conn.query_params["limit"] == "2"

            json(conn, [
              %{"user" => %{"id" => "10"}, "reason" => nil},
              %{"user" => %{"id" => "20"}, "reason" => nil}
            ])

          2 ->
            assert conn.query_params["before"] == "20"
            json(conn, [%{"user" => %{"id" => "30"}, "reason" => nil}])
        end
      end)

      bans = Ban.stream("111", per_page: 2) |> Enum.to_list()
      assert length(bans) == 3
      assert :counters.get(call_count, 1) == 2
    end

    test "empty guild returns empty stream", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/guilds/111/bans", fn conn ->
        json(conn, [])
      end)

      assert Ban.stream("111") |> Enum.to_list() == []
    end
  end
end
