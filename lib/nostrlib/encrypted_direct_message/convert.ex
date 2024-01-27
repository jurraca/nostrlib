defmodule Nostrlib.Models.EncryptedDirectMessage.Convert do
  @moduledoc """
  Convert a encrypted direct message model to a nostr event
  """

  alias Nostrlib.Keys.{PrivateKey, PublicKey}
  alias Nostrlib.{Event, Utils}
  alias Nostrlib.Crypto.AES256CBC

  alias Nostrlib.Models.EncryptedDirectMessage

  @encrypted_direct_message_kind 4

  @doc """
  Creates a new nostr encrypted direct message
  """
  @spec to_event(EncryptedDirectMessage.t(), PrivateKey.id()) ::
          {:ok, Event.t()} | {:error, String.t()}
  def to_event(
        %EncryptedDirectMessage{content: content, remote_pubkey: remote_pubkey},
        signing_private_key
      ) do
    with {:ok, binary_signing_pubkey} <- PublicKey.from_private_key(signing_private_key),
         {:ok, binary_remote_pubkey} <- PublicKey.to_binary(remote_pubkey),
         {:ok, binary_private_key} <- PrivateKey.to_binary(signing_private_key) do
      hex_remote_pubkey = Utils.to_hex(binary_remote_pubkey)

      encrypted_message = AES256CBC.encrypt(content, binary_private_key, binary_remote_pubkey)
      tags = [["p", hex_remote_pubkey]]

      {
        :ok,
        %{
          Event.create(@encrypted_direct_message_kind, encrypted_message, binary_signing_pubkey)
          | tags: tags
        }
      }
    end
  end
end
