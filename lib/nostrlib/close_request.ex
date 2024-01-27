defmodule Nostrlib.CloseRequest do
  @moduledoc """
  A CLOSED request sent from a relay to a client.
  """

  defstruct [:subscription_id]

  alias Nostrlib.CloseRequest

  @type t :: %CloseRequest{}
end
