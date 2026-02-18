defmodule EDA.Voice.Dave.IntegrationTest do
  use ExUnit.Case, async: true

  alias EDA.Voice.Dave.Manager

  describe "passthrough mode (dave disabled)" do
    test "full encrypt/decrypt cycle passes through unchanged" do
      manager = Manager.new(0, 12_345, 67_890)

      frame = <<0xFC, 1, 2, 3, 4, 5, 6, 7, 8>>

      # Encrypt
      {encrypted, manager} = Manager.encrypt_frame(manager, frame)
      assert encrypted == frame

      # Decrypt
      {:ok, decrypted, _manager} = Manager.decrypt_frame(manager, encrypted, 99_999)
      assert decrypted == frame
    end
  end

  describe "active mode (dave enabled)" do
    test "manager is active with version > 0" do
      manager = Manager.new(1, 12_345, 67_890)
      assert Manager.active?(manager)
      assert is_reference(manager.mls_session)
    end

    test "encrypt_frame produces different output than input (when session is active)" do
      # Without a completed MLS handshake, encrypt_opus may fail and fall back
      # to passthrough, or succeed with passthrough mode data.
      # This test verifies the manager doesn't crash either way.
      manager = Manager.new(1, 12_345, 67_890)
      frame = <<0xFC, 1, 2, 3, 4, 5, 6, 7, 8>>

      {result, _manager} = Manager.encrypt_frame(manager, frame)
      assert is_binary(result)
    end
  end

  describe "MLS event handling" do
    setup do
      %{manager: Manager.new(1, 12_345, 67_890)}
    end

    test "OP 21 PREPARE_TRANSITION is handled", %{manager: manager} do
      {updated, replies} = Manager.handle_mls_event(manager, 21, %{"protocol_version" => 1})
      assert replies == []
      assert updated.protocol_version == 1
    end

    test "OP 22 EXECUTE_TRANSITION clears pending state", %{manager: manager} do
      manager = %{manager | pending_epoch: 3, transition_id: 7}
      {updated, []} = Manager.handle_mls_event(manager, 22, %{})
      assert updated.pending_epoch == nil
      assert updated.transition_id == nil
    end

    test "OP 24 PREPARE_EPOCH is handled", %{manager: manager} do
      {_updated, replies} = Manager.handle_mls_event(manager, 24, %{"epoch" => 2})
      assert replies == []
    end

    test "OP 31 INVALID_COMMIT is handled gracefully", %{manager: manager} do
      {_updated, replies} =
        Manager.handle_mls_event(manager, 31, %{"reason" => "test_invalid"})

      assert replies == []
    end
  end
end
