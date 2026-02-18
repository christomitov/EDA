defmodule EDA.Voice.Dave.KeyStore do
  @moduledoc """
  Stores per-sender encryption keys across MLS epochs for DAVE E2EE.

  Maintains a mapping of `{ssrc, epoch} -> key` and tracks the current
  epoch's self-key and nonce counter.
  """

  defstruct keys: %{}, current_epoch: 0, self_key: nil, self_nonce: 0

  @type t :: %__MODULE__{
          keys: %{{non_neg_integer(), non_neg_integer()} => binary()},
          current_epoch: non_neg_integer(),
          self_key: binary() | nil,
          self_nonce: non_neg_integer()
        }

  @doc "Creates a new empty key store."
  @spec new() :: t()
  def new, do: %__MODULE__{}

  @doc "Stores a sender key for the given SSRC and epoch."
  @spec put_sender_key(t(), non_neg_integer(), non_neg_integer(), binary()) :: t()
  def put_sender_key(%__MODULE__{} = store, ssrc, epoch, key) do
    %{store | keys: Map.put(store.keys, {ssrc, epoch}, key)}
  end

  @doc "Retrieves the sender key for the given SSRC and epoch."
  @spec get_sender_key(t(), non_neg_integer(), non_neg_integer()) :: binary() | nil
  def get_sender_key(%__MODULE__{} = store, ssrc, epoch) do
    Map.get(store.keys, {ssrc, epoch})
  end

  @doc "Advances to a new epoch with the given self-key, resetting the nonce counter."
  @spec advance_epoch(t(), non_neg_integer(), binary()) :: t()
  def advance_epoch(%__MODULE__{} = store, new_epoch, self_key) do
    %{store | current_epoch: new_epoch, self_key: self_key, self_nonce: 0}
  end

  @doc "Returns the next nonce and an updated store with incremented counter."
  @spec next_nonce(t()) :: {non_neg_integer(), t()}
  def next_nonce(%__MODULE__{self_nonce: n} = store) do
    {n, %{store | self_nonce: n + 1}}
  end

  @doc """
  Removes keys from epochs older than the most recent `keep` epochs.
  """
  @spec prune_old_epochs(t(), non_neg_integer()) :: t()
  def prune_old_epochs(%__MODULE__{current_epoch: current} = store, keep \\ 2) do
    min_epoch = max(0, current - keep + 1)

    pruned =
      store.keys
      |> Enum.reject(fn {{_ssrc, epoch}, _key} -> epoch < min_epoch end)
      |> Map.new()

    %{store | keys: pruned}
  end
end
