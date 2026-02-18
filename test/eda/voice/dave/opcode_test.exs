defmodule EDA.Voice.Dave.OpcodeTest do
  use ExUnit.Case, async: true

  alias EDA.Voice.Payload

  describe "identify/5 with DAVE" do
    test "includes dave field when version > 0" do
      payload = Payload.identify("guild", "user", "session", "token", 1)
      assert payload.d.dave == %{protocol_version: 1}
    end

    test "omits dave field when version is 0" do
      payload = Payload.identify("guild", "user", "session", "token", 0)
      refute Map.has_key?(payload.d, :dave)
    end

    test "omits dave field by default" do
      payload = Payload.identify("guild", "user", "session", "token")
      refute Map.has_key?(payload.d, :dave)
    end
  end

  describe "dave_mls_key_package/1" do
    test "builds OP 26 with base64-encoded key package" do
      key_package = <<1, 2, 3, 4, 5>>
      payload = Payload.dave_mls_key_package(key_package)
      assert payload.op == 26
      assert payload.d.key_package == Base.encode64(key_package)
    end
  end

  describe "dave_ready_for_transition/1" do
    test "builds OP 23 with transition_id" do
      payload = Payload.dave_ready_for_transition(42)
      assert payload.op == 23
      assert payload.d.transition_id == 42
    end
  end

  describe "dave_mls_commit_welcome/2" do
    test "builds OP 28 with commit only" do
      commit = <<10, 20, 30>>
      payload = Payload.dave_mls_commit_welcome(commit)
      assert payload.op == 28
      assert payload.d.commit == Base.encode64(commit)
      refute Map.has_key?(payload.d, :welcome)
    end

    test "builds OP 28 with commit and welcome" do
      commit = <<10, 20, 30>>
      welcome = <<40, 50, 60>>
      payload = Payload.dave_mls_commit_welcome(commit, welcome)
      assert payload.op == 28
      assert payload.d.commit == Base.encode64(commit)
      assert payload.d.welcome == Base.encode64(welcome)
    end
  end
end
