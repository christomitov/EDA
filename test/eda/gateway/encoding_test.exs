defmodule EDA.Gateway.EncodingTest do
  use ExUnit.Case, async: true

  alias EDA.Gateway.Encoding

  describe "module/0" do
    test "defaults to ETF" do
      Application.delete_env(:eda, :gateway_encoding)
      assert Encoding.module() == EDA.Gateway.Encoding.ETF
    end

    test "returns JSON when configured" do
      Application.put_env(:eda, :gateway_encoding, :json)
      assert Encoding.module() == EDA.Gateway.Encoding.JSON
    after
      Application.delete_env(:eda, :gateway_encoding)
    end

    test "returns ETF when explicitly configured" do
      Application.put_env(:eda, :gateway_encoding, :etf)
      assert Encoding.module() == EDA.Gateway.Encoding.ETF
    after
      Application.delete_env(:eda, :gateway_encoding)
    end
  end
end
