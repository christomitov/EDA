defmodule EDA.Presence do
  @moduledoc """
  Presence and activity builder for Discord bots.

  Allows setting bot status (online, idle, dnd, invisible) and activities
  (playing, streaming, listening, watching, custom, competing).

  ## Examples

      # Build a presence with status and activity
      presence = EDA.Presence.new(
        status: :dnd,
        activities: [EDA.Presence.playing("Elixir")]
      )

      # Update at runtime
      EDA.set_presence(presence)

      # Convenience — just set an activity
      EDA.set_activity("Elixir", type: :playing)
  """

  @type status :: :online | :idle | :dnd | :invisible

  @type activity_type :: :playing | :streaming | :listening | :watching | :custom | :competing

  @type activity :: %{
          required(:name) => String.t(),
          required(:type) => activity_type(),
          optional(:url) => String.t()
        }

  @type t :: %__MODULE__{
          status: status(),
          activities: [activity()],
          afk: boolean(),
          since: integer() | nil
        }

  defstruct status: :online, activities: [], afk: false, since: nil

  @activity_type_map %{
    playing: 0,
    streaming: 1,
    listening: 2,
    watching: 3,
    custom: 4,
    competing: 5
  }

  @doc "Creates a Playing activity (type 0)."
  @spec playing(String.t()) :: activity()
  def playing(name), do: %{name: name, type: :playing}

  @doc "Creates a Streaming activity (type 1) with a Twitch/YouTube URL."
  @spec streaming(String.t(), String.t()) :: activity()
  def streaming(name, url), do: %{name: name, type: :streaming, url: url}

  @doc "Creates a Listening activity (type 2)."
  @spec listening(String.t()) :: activity()
  def listening(name), do: %{name: name, type: :listening}

  @doc "Creates a Watching activity (type 3)."
  @spec watching(String.t()) :: activity()
  def watching(name), do: %{name: name, type: :watching}

  @doc "Creates a Custom Status activity (type 4)."
  @spec custom(String.t()) :: activity()
  def custom(name), do: %{name: name, type: :custom}

  @doc "Creates a Competing activity (type 5)."
  @spec competing(String.t()) :: activity()
  def competing(name), do: %{name: name, type: :competing}

  @doc """
  Builds a `%Presence{}` struct from keyword options.

  ## Options

  - `:status` — `:online` | `:idle` | `:dnd` | `:invisible` (default `:online`)
  - `:activities` — list of activity maps from builder functions
  - `:afk` — boolean (default `false`)
  - `:since` — unix timestamp in milliseconds, or `nil`
  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    %__MODULE__{
      status: Keyword.get(opts, :status, :online),
      activities: Keyword.get(opts, :activities, []),
      afk: Keyword.get(opts, :afk, false),
      since: Keyword.get(opts, :since)
    }
  end

  @doc """
  Serializes a `%Presence{}` to the Discord gateway format.
  """
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = presence) do
    %{
      status: to_string(presence.status),
      activities: Enum.map(presence.activities, &serialize_activity/1),
      afk: presence.afk,
      since: presence.since
    }
  end

  @doc false
  def activity_type_value(type), do: Map.fetch!(@activity_type_map, type)

  defp serialize_activity(activity) do
    base = %{
      name: activity.name,
      type: Map.fetch!(@activity_type_map, activity.type)
    }

    if url = Map.get(activity, :url) do
      Map.put(base, :url, url)
    else
      base
    end
  end
end
