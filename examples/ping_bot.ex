defmodule PingBot.Consumer do
  @moduledoc """
  Example Discord bot using EDA.

  This bot responds to:
  - `!ping` - Responds with "Pong!"
  - `!hello` - Greets the user
  - `!info` - Shows bot info
  - `!guilds` - Shows number of cached guilds
  - `!templates` - Lists all guild templates
  - `!template <code>` - Shows details of a template by code
  - `!template-create <name>` - Creates a template from the current guild
  - `!template-sync <code>` - Syncs a template with current guild state
  - `!template-delete <code>` - Deletes a guild template

  ## Usage

  1. Set your bot token:

      export DISCORD_TOKEN="your_bot_token_here"

  2. Add this consumer to your config:

      config :eda,
        token: System.get_env("DISCORD_TOKEN"),
        intents: [:guilds, :guild_messages, :message_content],
        consumer: PingBot.Consumer

  3. Start the application:

      iex -S mix
  """

  @behaviour EDA.Consumer

  require Logger

  @impl true
  def handle_event({:MESSAGE_CREATE, msg}) do
    if msg[:author]["bot"] do
      :ignore
    else
      handle_command(msg)
    end
  end

  @impl true
  def handle_event({:READY, data}) do
    user = data[:user]
    guilds = data[:guilds] || []

    Logger.info("""
    Bot is ready!
    Username: #{user["username"]}
    User ID: #{user["id"]}
    Guilds: #{length(guilds)}
    """)
  end

  @impl true
  def handle_event({:GUILD_CREATE, guild}) do
    Logger.debug("Joined guild: #{guild[:name]} (#{guild[:id]})")
  end

  @impl true
  def handle_event(_event) do
    :ok
  end

  # Command handling

  defp handle_command(%{content: "!ping", channel_id: channel_id}) do
    start = System.monotonic_time(:millisecond)
    {:ok, _} = EDA.API.Message.create(channel_id, "Pong!")
    latency = System.monotonic_time(:millisecond) - start
    Logger.debug("Ping response sent in #{latency}ms")
  end

  defp handle_command(%{content: "!hello", channel_id: channel_id, author: author}) do
    username = author["username"]
    EDA.API.Message.create(channel_id, "Hello, #{username}!")
  end

  defp handle_command(%{content: "!info", channel_id: channel_id}) do
    me = EDA.Cache.me()
    guild_count = EDA.Cache.guild_count()
    user_count = EDA.Cache.user_count()
    channel_count = EDA.Cache.channel_count()

    message = """
    **EDA Bot Info**
    Bot: #{me["username"]}
    Guilds: #{guild_count}
    Cached Users: #{user_count}
    Cached Channels: #{channel_count}
    Library: EDA v0.1.0
    """

    EDA.API.Message.create(channel_id, message)
  end

  defp handle_command(%{content: "!guilds", channel_id: channel_id}) do
    guilds = EDA.Cache.guilds()

    guild_list =
      guilds
      |> Enum.take(10)
      |> Enum.map_join("\n", fn g -> "- #{g["name"]}" end)

    message =
      if length(guilds) > 10 do
        "**Guilds (showing 10 of #{length(guilds)}):**\n#{guild_list}"
      else
        "**Guilds:**\n#{guild_list}"
      end

    EDA.API.Message.create(channel_id, message)
  end

  # ── Guild Templates ─────────────────────────────────────────────────

  defp handle_command(%{content: "!templates", channel_id: channel_id, guild_id: guild_id}) do
    case EDA.API.GuildTemplate.list(guild_id) do
      {:ok, []} ->
        EDA.API.Message.create(channel_id, "No templates found for this guild.")

      {:ok, templates} ->
        list = Enum.map_join(templates, "\n", &format_template_line/1)
        EDA.API.Message.create(channel_id, "**Guild Templates:**\n#{list}")

      {:error, reason} ->
        EDA.API.Message.create(channel_id, "Failed to list templates: #{inspect(reason)}")
    end
  end

  defp handle_command(%{content: "!template " <> code, channel_id: channel_id}) do
    code = String.trim(code)

    case EDA.API.GuildTemplate.get(code) do
      {:ok, t} ->
        sg = t.serialized_source_guild

        roles_count = if sg && sg.roles, do: length(sg.roles), else: 0
        channels_count = if sg && sg.channels, do: length(sg.channels), else: 0

        desc = t.description || "_none_"
        dirty = if t.is_dirty, do: "Yes", else: "No"

        message = """
        **Template: #{t.name}**
        Code: `#{t.code}`
        Description: #{desc}
        Usage count: #{t.usage_count}
        Creator: <@#{t.creator_id}>
        Source guild: `#{t.source_guild_id}`
        Unsynced: #{dirty}
        Created: #{t.created_at}
        Updated: #{t.updated_at}
        Snapshot: **#{roles_count}** roles, **#{channels_count}** channels
        """

        EDA.API.Message.create(channel_id, message)

      {:error, reason} ->
        EDA.API.Message.create(
          channel_id,
          "Failed to get template `#{code}`: #{inspect(reason)}"
        )
    end
  end

  defp handle_command(%{
         content: "!template-create " <> name,
         channel_id: channel_id,
         guild_id: guild_id
       }) do
    name = String.trim(name)

    case EDA.API.GuildTemplate.create(guild_id, %{name: name}) do
      {:ok, t} ->
        EDA.API.Message.create(
          channel_id,
          "Template **#{t.name}** created with code `#{t.code}`."
        )

      {:error, reason} ->
        EDA.API.Message.create(channel_id, "Failed to create template: #{inspect(reason)}")
    end
  end

  defp handle_command(%{
         content: "!template-sync " <> code,
         channel_id: channel_id,
         guild_id: guild_id
       }) do
    code = String.trim(code)

    case EDA.API.GuildTemplate.sync(guild_id, code) do
      {:ok, t} ->
        EDA.API.Message.create(channel_id, "Template `#{t.code}` synced.")

      {:error, reason} ->
        EDA.API.Message.create(
          channel_id,
          "Failed to sync template `#{code}`: #{inspect(reason)}"
        )
    end
  end

  defp handle_command(%{
         content: "!template-delete " <> code,
         channel_id: channel_id,
         guild_id: guild_id
       }) do
    code = String.trim(code)

    case EDA.API.GuildTemplate.delete(guild_id, code) do
      {:ok, t} ->
        EDA.API.Message.create(channel_id, "Template **#{t.name}** (`#{t.code}`) deleted.")

      {:error, reason} ->
        EDA.API.Message.create(
          channel_id,
          "Failed to delete template `#{code}`: #{inspect(reason)}"
        )
    end
  end

  defp handle_command(_msg) do
    :ignore
  end

  defp format_template_line(t) do
    dirty = if t.is_dirty, do: " ⚠️ unsynced", else: ""
    "- `#{t.code}` — **#{t.name}** (used #{t.usage_count}x)#{dirty}"
  end
end
