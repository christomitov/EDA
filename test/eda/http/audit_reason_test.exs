defmodule EDA.HTTP.AuditReasonTest do
  use ExUnit.Case

  setup do
    bypass = Bypass.open()
    Application.put_env(:eda, :base_url, "http://localhost:#{bypass.port}")
    Application.put_env(:eda, :token, "test-token")

    on_exit(fn ->
      Application.delete_env(:eda, :base_url)
    end)

    {:ok, bypass: bypass}
  end

  defp json(conn, body, status \\ 200) do
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.resp(status, Jason.encode!(body))
  end

  describe "X-Audit-Log-Reason header" do
    test "reason option adds the header (URI-encoded)", %{bypass: bypass} do
      Bypass.expect_once(bypass, "PATCH", "/guilds/111", fn conn ->
        reason_header =
          Enum.find_value(conn.req_headers, fn
            {"x-audit-log-reason", value} -> value
            _ -> nil
          end)

        assert reason_header == URI.encode("Renamed by admin")
        json(conn, %{"id" => "111", "name" => "New"})
      end)

      assert {:ok, _} =
               EDA.API.Guild.modify("111", %{name: "New"}, reason: "Renamed by admin")
    end

    test "without reason option, header is absent", %{bypass: bypass} do
      Bypass.expect_once(bypass, "PATCH", "/guilds/111", fn conn ->
        reason_header =
          Enum.find_value(conn.req_headers, fn
            {"x-audit-log-reason", value} -> value
            _ -> nil
          end)

        assert is_nil(reason_header)
        json(conn, %{"id" => "111", "name" => "New"})
      end)

      assert {:ok, _} = EDA.API.Guild.modify("111", %{name: "New"})
    end
  end
end
