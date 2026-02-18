defmodule EDA.HTTP.ClientTest do
  use ExUnit.Case

  # Not async — shares the RateLimiter GenServer and Application env.

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

  # ── Error Handling ───────────────────────────────────────────────────

  describe "error responses" do
    test "4xx returns error with parsed body", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/channels/999", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(404, Jason.encode!(%{"message" => "Unknown Channel", "code" => 10_003}))
      end)

      assert {:error, %{status: 404, message: "Unknown Channel", code: 10_003}} =
               Channel.get("999")
    end

    test "rate limit triggers retry then succeeds", %{bypass: bypass} do
      call_count = :counters.new(1, [])

      Bypass.expect(bypass, "GET", "/channels/999", fn conn ->
        :counters.add(call_count, 1, 1)

        if :counters.get(call_count, 1) == 1 do
          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.resp(429, Jason.encode!(%{"retry_after" => 0.05, "global" => false}))
        else
          json(conn, %{"id" => "999", "name" => "test"})
        end
      end)

      assert {:ok, %{"id" => "999"}} = Channel.get("999")
      assert :counters.get(call_count, 1) == 2
    end
  end
end
