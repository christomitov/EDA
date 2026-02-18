defmodule EDA.HTTP.MultipartTest do
  use ExUnit.Case, async: true

  alias EDA.HTTP.Multipart
  alias EDA.File, as: F

  describe "encode/2" do
    test "produces valid multipart body with boundary" do
      file = F.from_binary("hello", "test.txt")
      {body_iodata, content_type} = Multipart.encode(%{content: "hi"}, [file])

      body = IO.iodata_to_binary(body_iodata)

      assert content_type =~ "multipart/form-data; boundary="
      boundary = String.replace_prefix(content_type, "multipart/form-data; boundary=", "")

      assert body =~ "--#{boundary}"
      assert body =~ "--#{boundary}--"
    end

    test "includes payload_json part with attachments array" do
      file = F.from_binary("data", "image.png", description: "Alt text")
      {body_iodata, _ct} = Multipart.encode(%{content: "look"}, [file])

      body = IO.iodata_to_binary(body_iodata)

      assert body =~ "payload_json"
      assert body =~ "application/json"

      # Extract JSON from payload_json part
      json_part = extract_json_payload(body)
      assert json_part["content"] == "look"
      assert length(json_part["attachments"]) == 1

      [att] = json_part["attachments"]
      assert att["id"] == 0
      assert att["filename"] == "image.png"
      assert att["description"] == "Alt text"
    end

    test "multiple files are indexed correctly" do
      files = [
        F.from_binary("aaa", "a.txt"),
        F.from_binary("bbb", "b.png")
      ]

      {body_iodata, _ct} = Multipart.encode(%{}, files)
      body = IO.iodata_to_binary(body_iodata)

      assert body =~ ~s(name="files[0]")
      assert body =~ ~s(filename="a.txt")
      assert body =~ ~s(name="files[1]")
      assert body =~ ~s(filename="b.png")

      json_part = extract_json_payload(body)
      assert length(json_part["attachments"]) == 2
      assert Enum.at(json_part["attachments"], 0)["id"] == 0
      assert Enum.at(json_part["attachments"], 1)["id"] == 1
    end

    test "spoiler files get SPOILER_ prefix" do
      file = F.from_binary("data", "secret.png", spoiler: true)
      {body_iodata, _ct} = Multipart.encode(%{}, [file])

      body = IO.iodata_to_binary(body_iodata)
      assert body =~ ~s(filename="SPOILER_secret.png")

      json_part = extract_json_payload(body)
      [att] = json_part["attachments"]
      assert att["filename"] == "SPOILER_secret.png"
    end

    test "file data is included in body" do
      file = F.from_binary("binary content here", "doc.txt")
      {body_iodata, _ct} = Multipart.encode(%{}, [file])

      body = IO.iodata_to_binary(body_iodata)
      assert body =~ "binary content here"
    end
  end

  describe "mime_type/1" do
    test "common image types" do
      assert Multipart.mime_type("photo.png") == "image/png"
      assert Multipart.mime_type("photo.jpg") == "image/jpeg"
      assert Multipart.mime_type("photo.jpeg") == "image/jpeg"
      assert Multipart.mime_type("anim.gif") == "image/gif"
      assert Multipart.mime_type("sticker.webp") == "image/webp"
    end

    test "audio types" do
      assert Multipart.mime_type("song.mp3") == "audio/mpeg"
      assert Multipart.mime_type("voice.ogg") == "audio/ogg"
    end

    test "video types" do
      assert Multipart.mime_type("clip.mp4") == "video/mp4"
      assert Multipart.mime_type("clip.webm") == "video/webm"
    end

    test "other types" do
      assert Multipart.mime_type("doc.pdf") == "application/pdf"
      assert Multipart.mime_type("notes.txt") == "text/plain"
      assert Multipart.mime_type("archive.zip") == "application/zip"
    end

    test "unknown extension falls back to octet-stream" do
      assert Multipart.mime_type("file.xyz") == "application/octet-stream"
      assert Multipart.mime_type("noext") == "application/octet-stream"
    end

    test "case insensitive" do
      assert Multipart.mime_type("IMAGE.PNG") == "image/png"
      assert Multipart.mime_type("Song.MP3") == "audio/mpeg"
    end
  end

  describe "escape_filename/1" do
    test "escapes double quotes" do
      assert Multipart.escape_filename(~s(file"name.txt)) == ~s(file\\"name.txt)
    end

    test "escapes backslashes" do
      assert Multipart.escape_filename("file\\name.txt") == "file\\\\name.txt"
    end

    test "replaces newlines with underscores" do
      assert Multipart.escape_filename("file\nname.txt") == "file_name.txt"
      assert Multipart.escape_filename("file\r\nname.txt") == "file__name.txt"
    end

    test "handles combined special characters" do
      assert Multipart.escape_filename("a\"b\\c\nd.txt") == "a\\\"b\\\\c_d.txt"
    end

    test "passes through normal filenames unchanged" do
      assert Multipart.escape_filename("normal-file_123.png") == "normal-file_123.png"
    end
  end

  # Helper to extract the JSON payload from the multipart body
  defp extract_json_payload(body) do
    # Find the payload_json part and extract the JSON
    [_, after_disposition] = String.split(body, ~s(name="payload_json"), parts: 2)
    # Skip past the Content-Type header and blank line
    [_, json_and_rest] = String.split(after_disposition, "\r\n\r\n", parts: 2)
    # Take until the next boundary
    [json_str | _] = String.split(json_and_rest, "\r\n--", parts: 2)
    Jason.decode!(json_str)
  end
end
