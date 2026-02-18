defmodule EDA.Event.Helpers do
  @moduledoc false

  @doc "Converts a string-keyed map to atom keys (shallow)."
  def atomize(nil), do: nil

  def atomize(map) when is_map(map) do
    Map.new(map, fn
      {k, v} when is_binary(k) -> {String.to_atom(k), v}
      {k, v} -> {k, v}
    end)
  end
end
