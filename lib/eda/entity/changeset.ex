defmodule EDA.Entity.Changeset do
  @moduledoc """
  Lightweight changeset for batching entity mutations into a single API call.

  ## Examples

      guild
      |> EDA.Guild.changeset()
      |> EDA.Guild.change(:name, "New Name")
      |> EDA.Guild.change(:icon, icon_data)
      |> EDA.Guild.apply_changeset(reason: "Rebranding")
  """

  defstruct [:entity, :module, changes: %{}]

  @type t :: %__MODULE__{entity: struct(), module: module(), changes: map()}

  @doc "Creates a new changeset for the given entity."
  @spec new(struct(), module()) :: t()
  def new(entity, module), do: %__MODULE__{entity: entity, module: module}

  @doc "Puts a change into the changeset."
  @spec put(t(), atom(), term()) :: t()
  def put(%__MODULE__{} = cs, key, value) when is_atom(key) do
    %{cs | changes: Map.put(cs.changes, key, value)}
  end

  @doc "Returns true if the changeset has any changes."
  @spec changed?(t()) :: boolean()
  def changed?(%__MODULE__{changes: changes}), do: changes != %{}

  @doc "Returns the accumulated changes as a map."
  @spec changes(t()) :: map()
  def changes(%__MODULE__{changes: changes}), do: changes
end
