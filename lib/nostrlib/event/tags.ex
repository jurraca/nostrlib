defmodule Nostrlib.Event.Tags do

  use Flint

  alias Nostrlib.Event.Tag

  embedded_schema do
    embeds_many :tags, Tag
  end

  def parse(tags) when is_list(tags) do
    parsed = Enum.map(tags, fn t -> Tag.parse(t) end)
    new(parsed)
  end
end
