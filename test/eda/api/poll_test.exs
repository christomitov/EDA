defmodule EDA.API.PollTest do
  use ExUnit.Case

  alias EDA.API.Poll

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

  # ── expire/2 ────────────────────────────────────────────────────────

  describe "expire/2" do
    test "POST /channels/:ch/polls/:msg/expire", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/channels/111/polls/222/expire", fn conn ->
        json(conn, %{"id" => "222", "poll" => %{}})
      end)

      assert {:ok, %{"id" => "222"}} = Poll.expire("111", "222")
    end
  end

  # ── get_voters/4 ────────────────────────────────────────────────────

  describe "get_voters/4" do
    test "GET /channels/:ch/polls/:msg/answers/:id", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/channels/111/polls/222/answers/1", fn conn ->
        json(conn, %{"users" => [%{"id" => "u1"}]})
      end)

      assert {:ok, %{"users" => [%{"id" => "u1"}]}} = Poll.get_voters("111", "222", 1)
    end

    test "passes pagination query params", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/channels/111/polls/222/answers/1", fn conn ->
        conn = Plug.Conn.fetch_query_params(conn)
        assert conn.query_params["after"] == "999"
        assert conn.query_params["limit"] == "50"
        json(conn, %{"users" => []})
      end)

      assert {:ok, _} = Poll.get_voters("111", "222", 1, after: "999", limit: 50)
    end
  end
end
