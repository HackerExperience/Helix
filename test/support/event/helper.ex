defmodule Helix.Test.Event.Helper do

  alias Helix.Event

  def emit(event) do
    Event.emit(event)
  end
end
