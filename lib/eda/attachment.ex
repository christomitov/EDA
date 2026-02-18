defmodule EDA.Attachment do
  @moduledoc "Represents a Discord message attachment."
  use EDA.Event.Access

  defstruct [
    :id,
    :filename,
    :description,
    :content_type,
    :size,
    :url,
    :proxy_url,
    :height,
    :width,
    :ephemeral,
    :duration_secs,
    :waveform
  ]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          filename: String.t() | nil,
          description: String.t() | nil,
          content_type: String.t() | nil,
          size: integer() | nil,
          url: String.t() | nil,
          proxy_url: String.t() | nil,
          height: integer() | nil,
          width: integer() | nil,
          ephemeral: boolean() | nil,
          duration_secs: number() | nil,
          waveform: String.t() | nil
        }

  @spec from_raw(map()) :: t()
  def from_raw(raw) when is_map(raw) do
    %__MODULE__{
      id: raw["id"],
      filename: raw["filename"],
      description: raw["description"],
      content_type: raw["content_type"],
      size: raw["size"],
      url: raw["url"],
      proxy_url: raw["proxy_url"],
      height: raw["height"],
      width: raw["width"],
      ephemeral: raw["ephemeral"],
      duration_secs: raw["duration_secs"],
      waveform: raw["waveform"]
    }
  end
end
