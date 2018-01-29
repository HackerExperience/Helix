defmodule Helix.Event.Utils do

  alias Helix.Event
  alias Helix.Network.Model.Bounce
  alias Helix.Network.Query.Bounce, as: BounceQuery

  def fetch_bounce(bounce = %Bounce{}),
    do: bounce
  def fetch_bounce(bounce_id = %Bounce.ID{}),
    do: fetch_bounce(BounceQuery.fetch(bounce_id))
  def fetch_bounce(nil),
    do: nil

  defmacro put_bounce(event, bounce) do
    quote do
      Event.set_bounce(
        unquote(event),
        fetch_bounce(unquote(bounce))
      )
    end
  end

  defmacro put_process(event, process) do
    quote do
      Event.set_process(unquote(event), unquote(process))
    end
  end
end
