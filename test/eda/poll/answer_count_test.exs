defmodule EDA.Poll.AnswerCountTest do
  use ExUnit.Case, async: true

  alias EDA.Poll.AnswerCount

  describe "from_raw/1" do
    test "parses id, count, and me_voted" do
      raw = %{"id" => 1, "count" => 42, "me_voted" => false}
      count = AnswerCount.from_raw(raw)

      assert %AnswerCount{id: 1, count: 42, me_voted: false} = count
    end
  end
end
