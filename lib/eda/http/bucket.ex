defmodule EDA.HTTP.Bucket do
  @moduledoc """
  Computes rate limit bucket keys from HTTP method and path.

  Discord rate limits are per-route, but some routes share buckets based on
  "major parameters" (guild_id, channel_id, webhook_id). This module
  normalizes paths so that requests to the same bucket get the same key.

  ## Rules

  - Guild ID, channel ID, and webhook ID are preserved (major parameters)
  - Other snowflake IDs are replaced with `:id`
  - `DELETE` on message endpoints gets a `DELETE:` prefix (separate bucket)
  """

  @doc """
  Computes a bucket key for the given HTTP method and API path.

  ## Examples

      iex> EDA.HTTP.Bucket.key(:get, "/guilds/123/bans/456")
      "/guilds/123/bans/:id"

      iex> EDA.HTTP.Bucket.key(:delete, "/channels/789/messages/111")
      "DELETE:/channels/789/messages/:id"

  """
  @spec key(atom(), String.t()) :: String.t()
  def key(method, path) do
    # Strip query string
    path = path |> String.split("?") |> hd()

    segments = String.split(path, "/")
    normalized = normalize_segments(segments, [])
    result = Enum.join(normalized, "/")

    if method == :delete and String.contains?(result, "/messages/") do
      "DELETE:" <> result
    else
      result
    end
  end

  # Walk segments pairwise: keep the ID after major-parameter prefixes,
  # replace other snowflake-like IDs with :id
  defp normalize_segments([], acc), do: Enum.reverse(acc)

  defp normalize_segments([segment | rest], acc) do
    if snowflake?(segment) do
      case acc do
        # Major parameters — preserve the ID
        ["channels" | _] -> normalize_segments(rest, [segment | acc])
        ["guilds" | _] -> normalize_segments(rest, [segment | acc])
        ["webhooks" | _] -> normalize_segments(rest, [segment | acc])
        # Non-major snowflake — replace
        _ -> normalize_segments(rest, [":id" | acc])
      end
    else
      normalize_segments(rest, [segment | acc])
    end
  end

  defp snowflake?(segment) do
    byte_size(segment) >= 17 and match?({_, ""}, Integer.parse(segment))
  end
end
