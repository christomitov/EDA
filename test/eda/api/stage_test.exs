defmodule EDA.API.StageTest do
  use ExUnit.Case

  alias EDA.API.Stage

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

  # ── create_stage_instance ──────────────────────────────────────────

  describe "create/1" do
    test "POST /stage-instances", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/stage-instances", fn conn ->
        {body, conn} = read_json_body(conn)
        assert body["channel_id"] == "ch1"
        assert body["topic"] == "Q&A"
        json(conn, %{"id" => "stage1", "channel_id" => "ch1", "topic" => "Q&A"})
      end)

      assert {:ok, %{"topic" => "Q&A"}} =
               Stage.create(%{channel_id: "ch1", topic: "Q&A"})
    end
  end

  # ── get_stage_instance ─────────────────────────────────────────────

  describe "get/1" do
    test "GET /stage-instances/:channel_id", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/stage-instances/ch1", fn conn ->
        json(conn, %{"id" => "stage1", "channel_id" => "ch1", "topic" => "Q&A"})
      end)

      assert {:ok, %{"topic" => "Q&A"}} = Stage.get("ch1")
    end
  end

  # ── modify_stage_instance ──────────────────────────────────────────

  describe "modify/2" do
    test "PATCH /stage-instances/:channel_id", %{bypass: bypass} do
      Bypass.expect_once(bypass, "PATCH", "/stage-instances/ch1", fn conn ->
        {body, conn} = read_json_body(conn)
        assert body["topic"] == "Updated"
        json(conn, %{"id" => "stage1", "topic" => "Updated"})
      end)

      assert {:ok, %{"topic" => "Updated"}} =
               Stage.modify("ch1", %{topic: "Updated"})
    end
  end

  # ── delete_stage_instance ──────────────────────────────────────────

  describe "delete/1" do
    test "DELETE /stage-instances/:channel_id", %{bypass: bypass} do
      Bypass.expect_once(bypass, "DELETE", "/stage-instances/ch1", fn conn ->
        Plug.Conn.resp(conn, 204, "")
      end)

      assert :ok = Stage.delete("ch1")
    end
  end
end
