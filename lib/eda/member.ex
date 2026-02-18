defmodule EDA.Member do
  @moduledoc "Represents a Discord guild member."
  use EDA.Event.Access

  defstruct [
    :user,
    :nick,
    :avatar,
    :roles,
    :joined_at,
    :premium_since,
    :deaf,
    :mute,
    :pending,
    :communication_disabled_until
  ]

  @type t :: %__MODULE__{
          user: EDA.User.t() | nil,
          nick: String.t() | nil,
          avatar: String.t() | nil,
          roles: [String.t()] | nil,
          joined_at: String.t() | nil,
          premium_since: String.t() | nil,
          deaf: boolean() | nil,
          mute: boolean() | nil,
          pending: boolean() | nil,
          communication_disabled_until: String.t() | nil
        }

  @spec from_raw(map()) :: t()
  def from_raw(raw) when is_map(raw) do
    %__MODULE__{
      user: parse_user(raw["user"]),
      nick: raw["nick"],
      avatar: raw["avatar"],
      roles: raw["roles"],
      joined_at: raw["joined_at"],
      premium_since: raw["premium_since"],
      deaf: raw["deaf"],
      mute: raw["mute"],
      pending: raw["pending"],
      communication_disabled_until: raw["communication_disabled_until"]
    }
  end

  defp parse_user(nil), do: nil
  defp parse_user(raw) when is_map(raw), do: EDA.User.from_raw(raw)

  # ── Entity Manager ──

  use EDA.Entity

  @doc """
  Fetches a member by guild ID and user ID. Checks cache first, falls back to REST.
  """
  @spec fetch_member(String.t() | integer(), String.t() | integer()) ::
          {:ok, t()} | {:error, term()}
  def fetch_member(guild_id, user_id) do
    case EDA.Cache.get_member(guild_id, user_id) do
      nil -> EDA.API.Member.get(guild_id, user_id) |> parse_response()
      raw -> {:ok, from_raw(raw)}
    end
  end

  @doc """
  Modifies a guild member.

  ## Options

  - `:reason` - Audit log reason
  """
  @spec modify(String.t() | integer(), t() | String.t() | integer(), map(), keyword()) ::
          {:ok, t()} | {:error, term()}
  def modify(guild_id, member, payload, opts \\ [])

  def modify(guild_id, %__MODULE__{user: %{id: uid}}, payload, opts),
    do: modify(guild_id, uid, payload, opts)

  def modify(guild_id, user_id, payload, opts)
      when (is_binary(user_id) or is_integer(user_id)) and is_map(payload) do
    EDA.API.Member.modify(guild_id, user_id, payload, opts) |> parse_response()
  end

  @doc """
  Kicks a member from a guild.

  ## Options

  - `:reason` - Audit log reason
  """
  @spec kick(String.t() | integer(), t() | String.t() | integer(), keyword()) ::
          :ok | {:error, term()}
  def kick(guild_id, member, opts \\ [])

  def kick(guild_id, %__MODULE__{user: %{id: uid}}, opts), do: kick(guild_id, uid, opts)

  def kick(guild_id, user_id, opts) when is_binary(user_id) or is_integer(user_id) do
    EDA.API.Member.remove(guild_id, user_id, opts)
  end

  @doc """
  Adds a role to a guild member.

  ## Options

  - `:reason` - Audit log reason
  """
  @spec add_role(
          String.t() | integer(),
          t() | String.t() | integer(),
          String.t() | integer(),
          keyword()
        ) :: :ok | {:error, term()}
  def add_role(guild_id, member, role_id, opts \\ [])

  def add_role(guild_id, %__MODULE__{user: %{id: uid}}, role_id, opts),
    do: add_role(guild_id, uid, role_id, opts)

  def add_role(guild_id, user_id, role_id, opts)
      when is_binary(user_id) or is_integer(user_id) do
    EDA.API.Member.add_role(guild_id, user_id, role_id, opts)
  end

  @doc """
  Removes a role from a guild member.

  ## Options

  - `:reason` - Audit log reason
  """
  @spec remove_role(
          String.t() | integer(),
          t() | String.t() | integer(),
          String.t() | integer(),
          keyword()
        ) :: :ok | {:error, term()}
  def remove_role(guild_id, member, role_id, opts \\ [])

  def remove_role(guild_id, %__MODULE__{user: %{id: uid}}, role_id, opts),
    do: remove_role(guild_id, uid, role_id, opts)

  def remove_role(guild_id, user_id, role_id, opts)
      when is_binary(user_id) or is_integer(user_id) do
    EDA.API.Member.remove_role(guild_id, user_id, role_id, opts)
  end

  @doc """
  Applies a changeset to a member. No-op if the changeset has no changes.

  Requires `guild_id` since members are guild-scoped.

  ## Options

  - `:reason` - Audit log reason
  """
  @spec apply_changeset(String.t() | integer(), Changeset.t(), keyword()) ::
          {:ok, t()} | {:error, term()}
  def apply_changeset(guild_id, changeset, opts \\ [])

  def apply_changeset(guild_id, %Changeset{module: __MODULE__, entity: entity} = cs, opts) do
    if Changeset.changed?(cs) do
      modify(guild_id, entity, Changeset.changes(cs), opts)
    else
      {:ok, entity}
    end
  end
end
