defmodule Nostrlib.Profile do
  @moduledoc """
  Kind 0 user metadata.
  """
  use Flint

  # @enforce_keys [:about, :name, :picture]
  # defstruct [:about, :name, :picture, :bot, :banner, :display_name, :website]

  alias Nostrlib.{Event, Utils}
  alias Nostrlib.Keys.PublicKey
  alias __MODULE__

  @kind 0

   embedded_schema  do
     field! :about, :string
     field! :name, :string
     field! :picture, :string
     field :bot, :boolean
     field :banner, :string
     field :display_name, :string
     field :website, :string
   end

  def update(profile, params) do
   case profile
     |> Profile.changeset(params)
     |> Ecto.Changeset.apply_action(:insert) do
     {:ok, data} -> {:ok, data}
     {:error, changeset} -> {:error, format_errors(changeset.errors)}
     end
  end

  @spec to_event(%__MODULE__{}, Map.t()) :: {:ok, Event.t()} | {:error, String.t()}
  def to_event(%__MODULE__{} = profile, privkey) do
    with {:ok, pubkey} <- PublicKey.from_private_key(privkey),
         hex_pubkey <- Utils.to_hex(pubkey) do
      content = filter_nils(profile) |> Jason.encode!
      Event.create(@kind, content, hex_pubkey) |> Event.sign(privkey)
    end
  end

  def to_event_serialized(profile, privkey) do
    to_event(profile, privkey) |> Event.sign_and_serialize(privkey)
  end

  def filter_nils(%Profile{} = profile) do
    profile
    |> Map.from_struct()
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Enum.into(%{})
  end

  defp format_errors(errors) do
    errors
    |> Enum.map(fn {k, v} -> Atom.to_string(k) <> " " <> elem(v, 0) end)
    |> Enum.join(",")
  end
end
