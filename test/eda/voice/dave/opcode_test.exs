defmodule EDA.Voice.Dave.OpcodeTest do
  use ExUnit.Case, async: true

  alias EDA.Voice.Payload

  describe "identify/5 with DAVE" do
    test "includes max_dave_protocol_version when version > 0" do
      payload = Payload.identify("guild", "user", "session", "token", 1)
      assert payload.d.max_dave_protocol_version == 1
    end

    test "omits max_dave_protocol_version when version is 0" do
      payload = Payload.identify("guild", "user", "session", "token", 0)
      refute Map.has_key?(payload.d, :max_dave_protocol_version)
    end

    test "omits max_dave_protocol_version by default" do
      payload = Payload.identify("guild", "user", "session", "token")
      refute Map.has_key?(payload.d, :max_dave_protocol_version)
    end
  end

  describe "dave_mls_key_package/1" do
    test "builds OP 26 binary frame with raw key package bytes" do
      key_package = <<1, 2, 3, 4, 5>>
      assert {:binary, <<26, ^key_package::binary>>} = Payload.dave_mls_key_package(key_package)
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
    test "builds OP 28 binary frame with commit only" do
      commit = <<10, 20, 30>>
      assert {:binary, <<28, ^commit::binary>>} = Payload.dave_mls_commit_welcome(commit)
    end

    test "builds OP 28 binary frame with commit and welcome" do
      commit = <<10, 20, 30>>
      welcome = <<40, 50, 60>>

      assert {:binary, <<28, ^commit::binary, ^welcome::binary>>} =
               Payload.dave_mls_commit_welcome(commit, welcome)
    end
  end
end
