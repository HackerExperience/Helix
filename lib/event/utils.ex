defmodule Helix.Event.Utils do

  alias Helix.Event
  alias Helix.Network.Model.Bounce
  alias Helix.Network.Query.Bounce, as: BounceQuery

  @spec fetch_bounce(Bounce.idt | nil) ::
    Bounce.t | nil
  @doc """
  Fetches the bounce struct (if any).
  """
  def fetch_bounce(bounce = %Bounce{}),
    do: bounce
  def fetch_bounce(bounce_id = %Bounce.ID{}),
    do: fetch_bounce(BounceQuery.fetch(bounce_id))
  def fetch_bounce(nil),
    do: nil

  @doc """
  Helper to fetch the bounce struct and add it to the event's metadata.
  """
  defmacro put_bounce(event, bounce) do
    quote do
      Event.set_bounce(
        unquote(event),
        fetch_bounce(unquote(bounce))
      )
    end
  end

  @doc """
  Helper to add the process to the event's metadata
  """
  defmacro put_process(event, process) do
    quote do
      Event.set_process(unquote(event), unquote(process))
    end
  end
end
