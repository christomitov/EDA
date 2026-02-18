defmodule EDA.Gateway.CloseCodeTest do
  use ExUnit.Case, async: true

  alias EDA.Gateway.CloseCode

  describe "action/1" do
    test "fatal codes return :fatal" do
      for code <- [4004, 4010, 4011, 4012, 4013, 4014] do
        assert CloseCode.action(code) == :fatal, "expected :fatal for #{code}"
      end
    end

    test "resumable codes return :resume" do
      for code <- [4000, 4001, 4002, 4003, 4005, 4008, 1000, 1001, 1006] do
        assert CloseCode.action(code) == :resume, "expected :resume for #{code}"
      end
    end

    test "session reset codes return :session_reset" do
      for code <- [4007, 4009] do
        assert CloseCode.action(code) == :session_reset, "expected :session_reset for #{code}"
      end
    end

    test "zombie code 4900 returns :resume" do
      assert CloseCode.action(4900) == :resume
    end

    test "nil returns :reconnect" do
      assert CloseCode.action(nil) == :reconnect
    end

    test "unknown code returns :reconnect" do
      assert CloseCode.action(9999) == :reconnect
    end
  end

  describe "fatal?/1" do
    test "returns true for fatal codes" do
      assert CloseCode.fatal?(4004)
      assert CloseCode.fatal?(4014)
    end

    test "returns false for non-fatal codes" do
      refute CloseCode.fatal?(4000)
      refute CloseCode.fatal?(4900)
      refute CloseCode.fatal?(1000)
    end
  end

  describe "reason/1" do
    test "returns descriptive string for known codes" do
      assert CloseCode.reason(4004) == "Authentication failed (invalid token)"
      assert CloseCode.reason(4014) == "Disallowed intents"
      assert CloseCode.reason(4000) == "Unknown error"
      assert CloseCode.reason(4009) == "Session timed out"
      assert CloseCode.reason(4900) == "Zombie connection (missed heartbeat ACK)"
    end

    test "returns generic string for unknown codes" do
      assert CloseCode.reason(9999) == "Close code 9999"
    end
  end
end
