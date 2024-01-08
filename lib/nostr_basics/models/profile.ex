defmodule NostrBasics.Profile do
  @moduledoc """
  Represents a user's profile
  """

  defstruct [:about, :banner, :display_name, :lud16, :name, :nip05, :picture, :website]

  @type t :: %__MODULE__{}
  @reaction_kind 0

  alias NostrBasics.Event

  @doc """
  Creates a new nostr profile
  """
  @spec to_event(Profile.t(), PublicKey.id()) :: {:ok, Event.t()} | {:error, String.t()}
  def to_event(%Profile{} = profile, pubkey) do
    case encode(profile) do
      {:ok, json_profile} ->
        {
          :ok,
          Event.create(@reaction_kind, json_profile, pubkey)
        }

      {:error, message} ->
        {:error, message}
    end
  end

  def encode(
    %Profile{} = profile,
    opts
  ) do
    profile
    |> Map.from_struct()
    |> Enum.filter(&(&1 != nil))
    |> Enum.into(%{})
    |> Jason.encode(opts)
  end
end
