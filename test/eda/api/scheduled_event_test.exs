defmodule EDA.API.ScheduledEventTest do
  use ExUnit.Case

  alias EDA.API.ScheduledEvent

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

  # ── list_scheduled_events ──────────────────────────────────────────

  describe "list/2" do
    test "GET /guilds/:id/scheduled-events", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/guilds/111/scheduled-events", fn conn ->
        conn = Plug.Conn.fetch_query_params(conn)
        assert conn.query_params["with_user_count"] == "true"
        json(conn, [%{"id" => "evt1", "name" => "Game Night"}])
      end)

      assert {:ok, [%{"name" => "Game Night"}]} =
               ScheduledEvent.list("111", with_user_count: true)
    end
  end

  # ── get_scheduled_event ────────────────────────────────────────────

  describe "get/3" do
    test "GET /guilds/:id/scheduled-events/:eid", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/guilds/111/scheduled-events/evt1", fn conn ->
        json(conn, %{"id" => "evt1", "name" => "Game Night"})
      end)

      assert {:ok, %{"name" => "Game Night"}} = ScheduledEvent.get("111", "evt1")
    end
  end

  # ── create_scheduled_event ─────────────────────────────────────────

  describe "create/2" do
    test "POST /guilds/:id/scheduled-events", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/guilds/111/scheduled-events", fn conn ->
        {body, conn} = read_json_body(conn)
        assert body["name"] == "Game Night"
        assert body["entity_type"] == 3
        json(conn, %{"id" => "evt1", "name" => "Game Night"})
      end)

      assert {:ok, %{"name" => "Game Night"}} =
               ScheduledEvent.create("111", %{name: "Game Night", entity_type: 3})
    end
  end

  # ── modify_scheduled_event ─────────────────────────────────────────

  describe "modify/3" do
    test "PATCH /guilds/:id/scheduled-events/:eid", %{bypass: bypass} do
      Bypass.expect_once(bypass, "PATCH", "/guilds/111/scheduled-events/evt1", fn conn ->
        {body, conn} = read_json_body(conn)
        assert body["name"] == "Updated"
        json(conn, %{"id" => "evt1", "name" => "Updated"})
      end)

      assert {:ok, %{"name" => "Updated"}} =
               ScheduledEvent.modify("111", "evt1", %{name: "Updated"})
    end
  end

  # ── delete_scheduled_event ─────────────────────────────────────────

  describe "delete/2" do
    test "DELETE /guilds/:id/scheduled-events/:eid", %{bypass: bypass} do
      Bypass.expect_once(bypass, "DELETE", "/guilds/111/scheduled-events/evt1", fn conn ->
        Plug.Conn.resp(conn, 204, "")
      end)

      assert :ok = ScheduledEvent.delete("111", "evt1")
    end
  end

  # ── get_scheduled_event_users ──────────────────────────────────────

  describe "users/3" do
    test "GET /guilds/:id/scheduled-events/:eid/users", %{bypass: bypass} do
      Bypass.expect_once(
        bypass,
        "GET",
        "/guilds/111/scheduled-events/evt1/users",
        fn conn ->
          conn = Plug.Conn.fetch_query_params(conn)
          assert conn.query_params["limit"] == "10"
          json(conn, [%{"user" => %{"id" => "u1"}}])
        end
      )

      assert {:ok, [%{"user" => %{"id" => "u1"}}]} =
               ScheduledEvent.users("111", "evt1", limit: 10)
    end
  end

  # ── user_stream ──────────────────────────────────────────────────────

  describe "user_stream/3" do
    test "paginates event users across pages", %{bypass: bypass} do
      call_count = :counters.new(1, [])

      Bypass.expect(bypass, "GET", "/guilds/111/scheduled-events/evt1/users", fn conn ->
        :counters.add(call_count, 1, 1)
        conn = Plug.Conn.fetch_query_params(conn)

        case :counters.get(call_count, 1) do
          1 ->
            assert conn.query_params["limit"] == "2"

            json(conn, [
              %{"user" => %{"id" => "u1"}},
              %{"user" => %{"id" => "u2"}}
            ])

          2 ->
            assert conn.query_params["before"] == "u2"
            json(conn, [%{"user" => %{"id" => "u3"}}])
        end
      end)

      users = ScheduledEvent.user_stream("111", "evt1", per_page: 2) |> Enum.to_list()
      assert length(users) == 3
    end

    test "passes with_member option", %{bypass: bypass} do
      Bypass.expect_once(
        bypass,
        "GET",
        "/guilds/111/scheduled-events/evt1/users",
        fn conn ->
          conn = Plug.Conn.fetch_query_params(conn)
          assert conn.query_params["with_member"] == "true"
          json(conn, [])
        end
      )

      ScheduledEvent.user_stream("111", "evt1", with_member: true) |> Enum.to_list()
    end
  end
end
