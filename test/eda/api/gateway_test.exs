defmodule EDA.API.GatewayTest do
  use ExUnit.Case

  alias EDA.API.Gateway

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

  defp assert_auth_header(conn) do
    assert Plug.Conn.get_req_header(conn, "authorization") == ["Bot test-token"]
    conn
  end

  # ── get_gateway_bot ────────────────────────────────────────────────

  describe "bot/0" do
    test "GET /gateway/bot", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/gateway/bot", fn conn ->
        conn
        |> assert_auth_header()
        |> json(%{
          "url" => "wss://gateway.discord.gg",
          "shards" => 3,
          "session_start_limit" => %{
            "total" => 1000,
            "remaining" => 999,
            "reset_after" => 14_400_000,
            "max_concurrency" => 1
          }
        })
      end)

      assert {:ok, %{"shards" => 3, "url" => "wss://gateway.discord.gg"}} =
               Gateway.bot()
    end
  end
end
