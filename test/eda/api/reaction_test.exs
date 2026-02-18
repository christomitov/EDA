defmodule EDA.API.ReactionTest do
  use ExUnit.Case

  alias EDA.API.Reaction

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

  # ── create_reaction ────────────────────────────────────────────────

  describe "create/3" do
    test "PUT .../reactions/:emoji/@me", %{bypass: bypass} do
      Bypass.expect_once(
        bypass,
        "PUT",
        "/channels/1/messages/2/reactions/%F0%9F%91%8D/@me",
        fn conn ->
          Plug.Conn.resp(conn, 204, "")
        end
      )

      assert :ok = Reaction.create("1", "2", "\u{1F44D}")
    end
  end

  # ── delete_own_reaction ────────────────────────────────────────────

  describe "delete_own/3" do
    test "DELETE .../reactions/:emoji/@me", %{bypass: bypass} do
      Bypass.expect_once(
        bypass,
        "DELETE",
        "/channels/1/messages/2/reactions/%F0%9F%91%8D/@me",
        fn conn ->
          Plug.Conn.resp(conn, 204, "")
        end
      )

      assert :ok = Reaction.delete_own("1", "2", "\u{1F44D}")
    end
  end

  # ── delete_user_reaction ───────────────────────────────────────────

  describe "delete_user/4" do
    test "DELETE .../reactions/:emoji/:user_id", %{bypass: bypass} do
      Bypass.expect_once(
        bypass,
        "DELETE",
        "/channels/1/messages/2/reactions/%F0%9F%91%8D/99",
        fn conn ->
          Plug.Conn.resp(conn, 204, "")
        end
      )

      assert :ok = Reaction.delete_user("1", "2", "\u{1F44D}", "99")
    end
  end

  # ── get_reactions ──────────────────────────────────────────────────

  describe "list/4" do
    test "GET .../reactions/:emoji with opts", %{bypass: bypass} do
      Bypass.expect_once(
        bypass,
        "GET",
        "/channels/1/messages/2/reactions/%F0%9F%91%8D",
        fn conn ->
          conn = Plug.Conn.fetch_query_params(conn)
          assert conn.query_params["limit"] == "10"
          json(conn, [%{"id" => "99"}])
        end
      )

      assert {:ok, [%{"id" => "99"}]} = Reaction.list("1", "2", "\u{1F44D}", limit: 10)
    end
  end

  # ── delete_all_reactions ───────────────────────────────────────────

  describe "delete_all/2" do
    test "DELETE .../reactions", %{bypass: bypass} do
      Bypass.expect_once(bypass, "DELETE", "/channels/1/messages/2/reactions", fn conn ->
        Plug.Conn.resp(conn, 204, "")
      end)

      assert :ok = Reaction.delete_all("1", "2")
    end
  end

  # ── delete_emoji_reactions ─────────────────────────────────────────

  describe "delete_emoji/3" do
    test "DELETE .../reactions/:emoji", %{bypass: bypass} do
      Bypass.expect_once(
        bypass,
        "DELETE",
        "/channels/1/messages/2/reactions/%F0%9F%91%8D",
        fn conn ->
          Plug.Conn.resp(conn, 204, "")
        end
      )

      assert :ok = Reaction.delete_emoji("1", "2", "\u{1F44D}")
    end
  end

  # ── Reactions with Emoji struct ────────────────────────────────────

  describe "reactions with Emoji struct" do
    test "create accepts unicode Emoji struct", %{bypass: bypass} do
      Bypass.expect_once(
        bypass,
        "PUT",
        "/channels/1/messages/2/reactions/%F0%9F%91%8D/@me",
        fn conn ->
          Plug.Conn.resp(conn, 204, "")
        end
      )

      emoji = %EDA.Emoji{id: nil, name: "\u{1F44D}"}
      assert :ok = Reaction.create("1", "2", emoji)
    end

    test "delete_own accepts unicode Emoji struct", %{bypass: bypass} do
      Bypass.expect_once(
        bypass,
        "DELETE",
        "/channels/1/messages/2/reactions/%F0%9F%91%8D/@me",
        fn conn ->
          Plug.Conn.resp(conn, 204, "")
        end
      )

      emoji = %EDA.Emoji{id: nil, name: "\u{1F44D}"}
      assert :ok = Reaction.delete_own("1", "2", emoji)
    end

    test "list accepts unicode Emoji struct", %{bypass: bypass} do
      Bypass.expect_once(
        bypass,
        "GET",
        "/channels/1/messages/2/reactions/%F0%9F%91%8D",
        fn conn ->
          json(conn, [%{"id" => "99"}])
        end
      )

      emoji = %EDA.Emoji{id: nil, name: "\u{1F44D}"}
      assert {:ok, [%{"id" => "99"}]} = Reaction.list("1", "2", emoji)
    end
  end

  # ── stream ───────────────────────────────────────────────────────────

  describe "stream/4" do
    test "paginates users after-only", %{bypass: bypass} do
      call_count = :counters.new(1, [])

      Bypass.expect(bypass, "GET", "/channels/1/messages/2/reactions/%F0%9F%91%8D", fn conn ->
        :counters.add(call_count, 1, 1)
        conn = Plug.Conn.fetch_query_params(conn)

        case :counters.get(call_count, 1) do
          1 ->
            assert conn.query_params["limit"] == "2"
            json(conn, [%{"id" => "10"}, %{"id" => "20"}])

          2 ->
            assert conn.query_params["after"] == "20"
            json(conn, [%{"id" => "30"}])
        end
      end)

      users = Reaction.stream("1", "2", "\u{1F44D}", per_page: 2) |> Enum.to_list()
      assert length(users) == 3
    end

    test "empty reactions returns empty stream", %{bypass: bypass} do
      Bypass.expect_once(
        bypass,
        "GET",
        "/channels/1/messages/2/reactions/%F0%9F%91%8D",
        fn conn ->
          json(conn, [])
        end
      )

      assert Reaction.stream("1", "2", "\u{1F44D}") |> Enum.to_list() == []
    end
  end
end
