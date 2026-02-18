defmodule EDA.AttachmentTest do
  use ExUnit.Case, async: true

  alias EDA.Attachment

  describe "from_raw/1" do
    test "parses all fields" do
      raw = %{
        "id" => "att1",
        "filename" => "image.png",
        "description" => "A photo",
        "content_type" => "image/png",
        "size" => 12_345,
        "url" => "https://cdn.example.com/image.png",
        "proxy_url" => "https://proxy.example.com/image.png",
        "height" => 100,
        "width" => 200,
        "ephemeral" => false,
        "duration_secs" => 3.5,
        "waveform" => "base64data"
      }

      att = Attachment.from_raw(raw)
      assert %Attachment{} = att
      assert att.id == "att1"
      assert att.filename == "image.png"
      assert att.size == 12_345
      assert att.height == 100
      assert att.width == 200
    end

    test "handles missing optional fields" do
      att = Attachment.from_raw(%{"id" => "1", "filename" => "f.txt"})
      assert att.height == nil
      assert att.content_type == nil
    end
  end
end
