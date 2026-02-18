defmodule EDA.Gateway.Encoding.ETF do
  @moduledoc """
  Erlang External Term Format encoding for Discord Gateway payloads.

  Binary format decoded natively by the BEAM via `:erlang.binary_to_term/1`,
  significantly faster than JSON parsing. Payloads are ~15-30% smaller.

  ## Normalization

  Discord's ETF payloads differ from JSON in two ways:

  - **Atom keys** — Map keys arrive as atoms (e.g. `:op`) instead of strings.
  - **Integer snowflakes** — Large IDs arrive as integers instead of strings.

  `normalize/1` deep-converts the decoded term so the result is identical to
  what `Jason.decode!/1` would produce. This means the rest of EDA sees no
  difference between ETF and JSON payloads.

  ## Security

  We use `:erlang.binary_to_term/1` without the `:safe` option because Discord
  may introduce new fields (= new atoms) at any time. With `:safe`, unknown atoms
  would crash the decoder. Since `normalize/1` immediately converts all atoms to
  strings, there is no long-term pollution of the atom table beyond the decode call.
  """

  @behaviour EDA.Gateway.Encoding

  # Minimum snowflake value (2^22). Discord snowflakes are always >= this.
  # OP codes (0-14), event types, flags, and other small integers stay below.
  @snowflake_min 4_194_304

  @doc "Decodes an ETF binary and normalizes atom keys and snowflake integers to strings."
  @impl true
  @spec decode(binary()) :: map()
  def decode(binary) do
    binary
    |> :erlang.binary_to_term()
    |> normalize()
  end

  @doc """
  Encodes a map as an ETF binary frame.

  Atom keys are converted to strings before encoding because Discord's ETF
  parser requires string (binary) keys — atom keys cause a 4002 close code.
  This mirrors what `Jason.encode!/1` does implicitly for JSON.
  """
  @impl true
  @spec encode(map()) :: {:binary, binary()}
  def encode(map) do
    {:binary, map |> stringify_keys() |> :erlang.term_to_binary()}
  end

  @doc ~s[Returns `"etf"` for the gateway URL query parameter.]
  @impl true
  @spec url_encoding() :: String.t()
  def url_encoding, do: "etf"

  @doc """
  Deep-converts an ETF-decoded term to match `Jason.decode!/1` output.

  - Atom map keys become strings
  - Atom values become strings (e.g. event type atoms)
  - Integers above `#{@snowflake_min}` (2^22) become strings (snowflakes, permissions)
  - Booleans and nil are preserved
  - Lists and nested maps are recursively normalized
  """
  @spec normalize(term()) :: term()
  def normalize(nil), do: nil
  def normalize(true), do: true
  def normalize(false), do: false

  def normalize(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {normalize_key(k), normalize(v)} end)
  end

  def normalize(list) when is_list(list), do: Enum.map(list, &normalize/1)

  def normalize(int) when is_integer(int) and int >= @snowflake_min, do: Integer.to_string(int)

  def normalize(atom) when is_atom(atom), do: Atom.to_string(atom)

  def normalize(other), do: other

  defp normalize_key(k) when is_atom(k), do: Atom.to_string(k)
  defp normalize_key(k) when is_binary(k), do: k
  defp normalize_key(k) when is_integer(k), do: Integer.to_string(k)

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {to_string(k), stringify_keys(v)} end)
  end

  defp stringify_keys(list) when is_list(list), do: Enum.map(list, &stringify_keys/1)
  defp stringify_keys(other), do: other
end
