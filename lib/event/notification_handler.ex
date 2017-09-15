defmodule Helix.Event.NotificationHandler do

  alias Helix.Event.Notificable

  def notification_handler(event) do
    event
    |> Notificable.whom_to_notify()
    |> Enum.each(&(Helix.Endpoint.broadcast(&1, "event", event)))
  end
end
