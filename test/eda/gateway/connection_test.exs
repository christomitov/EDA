defmodule EDA.Gateway.ConnectionTestHelper do
  @moduledoc false

  def browser_string(:desktop), do: "EDA"
  def browser_string(:mobile), do: "Discord iOS"
  def browser_string(:mobile_ios), do: "Discord iOS"
  def browser_string(:mobile_android), do: "Discord Android"
  def browser_string(:web), do: "EDA Web"
  def browser_string(custom) when is_binary(custom), do: custom

  def maybe_add_presence(d) do
    case Application.get_env(:eda, :presence) do
      %EDA.Presence{} = presence ->
        Map.put(d, :presence, EDA.Presence.to_map(presence))

      opts when is_list(opts) ->
        Map.put(d, :presence, EDA.Presence.to_map(EDA.Presence.new(opts)))

      _ ->
        d
    end
  end
end

defmodule EDA.Gateway.ConnectionTest do
  use ExUnit.Case, async: true

  describe "browser_string/1" do
    test "desktop returns EDA" do
      assert EDA.Gateway.ConnectionTestHelper.browser_string(:desktop) == "EDA"
    end

    test "mobile returns Discord iOS" do
      assert EDA.Gateway.ConnectionTestHelper.browser_string(:mobile) == "Discord iOS"
    end

    test "mobile_ios returns Discord iOS" do
      assert EDA.Gateway.ConnectionTestHelper.browser_string(:mobile_ios) == "Discord iOS"
    end

    test "mobile_android returns Discord Android" do
      assert EDA.Gateway.ConnectionTestHelper.browser_string(:mobile_android) == "Discord Android"
    end

    test "web returns EDA Web" do
      assert EDA.Gateway.ConnectionTestHelper.browser_string(:web) == "EDA Web"
    end

    test "binary string passes through" do
      assert EDA.Gateway.ConnectionTestHelper.browser_string("Custom Browser") == "Custom Browser"
    end
  end

  describe "maybe_add_presence/1" do
    test "adds presence when configured" do
      presence = EDA.Presence.new(status: :dnd, activities: [EDA.Presence.playing("Elixir")])
      Application.put_env(:eda, :presence, presence)

      d = %{token: "test", intents: 0}
      result = EDA.Gateway.ConnectionTestHelper.maybe_add_presence(d)

      assert Map.has_key?(result, :presence)
      assert result.presence.status == "dnd"
      assert result.presence.activities == [%{name: "Elixir", type: 0}]

      Application.delete_env(:eda, :presence)
    end

    test "does not add presence when not configured" do
      Application.delete_env(:eda, :presence)

      d = %{token: "test", intents: 0}
      result = EDA.Gateway.ConnectionTestHelper.maybe_add_presence(d)

      refute Map.has_key?(result, :presence)
    end

    test "does not add presence when set to nil" do
      Application.put_env(:eda, :presence, nil)

      d = %{token: "test", intents: 0}
      result = EDA.Gateway.ConnectionTestHelper.maybe_add_presence(d)

      refute Map.has_key?(result, :presence)

      Application.delete_env(:eda, :presence)
    end
  end

  describe "close code integration" do
    alias EDA.Gateway.CloseCode

    test "fatal close code 4004 maps to :fatal action" do
      assert CloseCode.action(4004) == :fatal
      assert CloseCode.reason(4004) == "Authentication failed (invalid token)"
    end

    test "session reset close code 4007 clears session" do
      assert CloseCode.action(4007) == :session_reset
    end

    test "resume close code 4000 keeps session" do
      assert CloseCode.action(4000) == :resume
    end

    test "unknown error defaults to :reconnect" do
      assert CloseCode.action(9999) == :reconnect
    end

    test "zombie code 4900 is resumable" do
      assert CloseCode.action(4900) == :resume
    end
  end
end
