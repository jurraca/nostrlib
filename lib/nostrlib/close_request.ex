defmodule Nostrlib.CloseRequest do
  @moduledoc """
  When a subscription's got to be closed... meant to be sent to a relay from a client.
  """

  defstruct [:subscription_id]

  alias Nostrlib.CloseRequest

  @type t :: %CloseRequest{}
end
