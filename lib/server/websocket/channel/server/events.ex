defmodule Helix.Server.Websocket.Channel.Server.Events do

  alias Helix.Event.Notificable

  def notification_handler(event) do
    event
    |> Notificable.whom_to_notify()
    |> Enum.each(fn server_id ->
      topic = "server:" <> to_string(server_id)

      Helix.Endpoint.broadcast(topic, "event", event)
    end)
  end
end
