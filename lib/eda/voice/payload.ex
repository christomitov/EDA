defmodule EDA.Voice.Payload do
  @moduledoc """
  Voice Gateway JSON payload builders (v8).

  Voice Gateway opcodes:
  - 0: IDENTIFY
  - 1: SELECT_PROTOCOL
  - 3: HEARTBEAT
  - 5: SPEAKING
  - 7: RESUME
  """

  @doc """
  Builds an IDENTIFY payload for voice gateway authentication.

  When `dave_version` is > 0, includes DAVE protocol negotiation.
  """
  def identify(server_id, user_id, session_id, token, dave_version \\ 0) do
    d = %{
      server_id: server_id,
      user_id: user_id,
      session_id: session_id,
      token: token
    }

    d =
      if dave_version > 0 do
        Map.put(d, :dave, %{protocol_version: dave_version})
      else
        d
      end

    %{op: 0, d: d}
  end

  @doc """
  Builds a SELECT_PROTOCOL payload with our IP discovery results and encryption mode.
  """
  def select_protocol(ip, port, mode) do
    %{
      op: 1,
      d: %{
        protocol: "udp",
        data: %{
          address: ip,
          port: port,
          mode: mode
        }
      }
    }
  end

  @doc """
  Builds a HEARTBEAT payload with the given nonce and seq_ack.
  """
  def heartbeat(nonce, seq_ack \\ 0) do
    %{op: 3, d: %{t: nonce, seq_ack: seq_ack}}
  end

  @doc """
  Builds a SPEAKING payload.

  Flags:
  - 1: Microphone (normal voice)
  - 2: Soundshare (go live / screen share audio)
  - 4: Priority speaker
  """
  def speaking(ssrc, speaking \\ true) do
    flags = if speaking, do: 1, else: 0

    %{
      op: 5,
      d: %{
        speaking: flags,
        delay: 0,
        ssrc: ssrc
      }
    }
  end

  @doc """
  Builds a RESUME payload for reconnecting to the voice gateway.
  """
  def resume(server_id, session_id, token) do
    %{
      op: 7,
      d: %{
        server_id: server_id,
        session_id: session_id,
        token: token
      }
    }
  end

  # DAVE (E2EE) Opcodes

  @doc """
  Builds a DAVE_MLS_KEY_PACKAGE payload (OP 26).

  Sends this client's MLS key package to the voice gateway.
  """
  def dave_mls_key_package(key_package_bytes) do
    %{op: 26, d: %{key_package: Base.encode64(key_package_bytes)}}
  end

  @doc """
  Builds a DAVE_READY_FOR_TRANSITION payload (OP 23).

  Confirms to the gateway that the client is ready for the protocol/epoch transition.
  """
  def dave_ready_for_transition(transition_id) do
    %{op: 23, d: %{transition_id: transition_id}}
  end

  @doc """
  Builds a DAVE_MLS_COMMIT_WELCOME payload (OP 28).

  Sends the MLS commit (and optional welcome) to the gateway after processing proposals.
  """
  def dave_mls_commit_welcome(commit_bytes, welcome_bytes \\ nil) do
    d = %{commit: Base.encode64(commit_bytes)}

    d =
      if welcome_bytes do
        Map.put(d, :welcome, Base.encode64(welcome_bytes))
      else
        d
      end

    %{op: 28, d: d}
  end
end
