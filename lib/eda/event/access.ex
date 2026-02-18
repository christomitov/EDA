defmodule EDA.Event.Access do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      @behaviour Access

      @impl Access
      def fetch(struct, key) when is_atom(key), do: Map.fetch(struct, key)

      def fetch(struct, key) when is_binary(key) do
        String.to_existing_atom(key) |> then(&Map.fetch(struct, &1))
      rescue
        ArgumentError -> :error
      end

      @impl Access
      def get_and_update(struct, key, fun) do
        atom_key = if is_binary(key), do: String.to_existing_atom(key), else: key
        Map.get_and_update(struct, atom_key, fun)
      end

      @impl Access
      def pop(struct, key) do
        atom_key = if is_binary(key), do: String.to_existing_atom(key), else: key
        Map.pop(struct, atom_key)
      end
    end
  end
end
