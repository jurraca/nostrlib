defmodule Nostrlib.CloseRequest do
  @moduledoc """
  A CLOSED request sent from a relay to a client.
  """

  def new(sub_id), do: Jason.encode!(["CLOSE", sub_id])
end
