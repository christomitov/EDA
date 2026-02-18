defmodule EDA.Poll.AnswerTest do
  use ExUnit.Case, async: true

  alias EDA.Poll.Answer

  describe "from_raw/1" do
    test "parses answer_id, text, and emoji" do
      raw = %{
        "answer_id" => 1,
        "poll_media" => %{
          "text" => "Yes",
          "emoji" => %{"id" => nil, "name" => "👍"}
        }
      }

      answer = Answer.from_raw(raw)
      assert %Answer{answer_id: 1, text: "Yes"} = answer
      assert %EDA.Emoji{name: "👍"} = answer.emoji
    end

    test "parses without emoji" do
      raw = %{
        "answer_id" => 2,
        "poll_media" => %{"text" => "No"}
      }

      answer = Answer.from_raw(raw)
      assert answer.answer_id == 2
      assert answer.text == "No"
      assert answer.emoji == nil
    end
  end

  describe "to_raw/1" do
    test "roundtrips text and emoji" do
      answer = %Answer{text: "Yes", emoji: %EDA.Emoji{id: nil, name: "👍"}}
      raw = Answer.to_raw(answer)

      assert raw == %{"poll_media" => %{"text" => "Yes", "emoji" => %{"name" => "👍"}}}
    end

    test "omits emoji when nil" do
      answer = %Answer{text: "No"}
      raw = Answer.to_raw(answer)

      assert raw == %{"poll_media" => %{"text" => "No"}}
    end

    test "includes id and name for custom emoji" do
      answer = %Answer{text: "Cool", emoji: %EDA.Emoji{id: "123", name: "cool"}}
      raw = Answer.to_raw(answer)

      assert raw == %{
               "poll_media" => %{"text" => "Cool", "emoji" => %{"id" => "123", "name" => "cool"}}
             }
    end
  end
end
