import Helix.Websocket.Request.Proxy

proxy_request Helix.Notification.Websocket.Requests.Read do
  @moduledoc """
  NotificationReadRequest will proxy the request to the appropriate backend, as
  described on its topic documentation at AccountChannel (check it out).
  """

  alias Helix.Notification.Websocket.Requests.Read.One,
    as: NotificationReadOneRequest
  alias Helix.Notification.Websocket.Requests.Read.All,
    as: NotificationReadAllRequest

  select_backend(request, _socket) do
    has_notification? = Map.has_key?(request.unsafe, "notification_id")
    has_class? = Map.has_key?(request.unsafe, "class")

    case {has_notification?, has_class?} do
      {true, false} ->
        {:ok, NotificationReadOneRequest}

      {false, true} ->
        {:ok, NotificationReadAllRequest}

      {true, true} ->
        {:error, :read_the_docs}

      {false, false} ->
        {:error, :bad_request}
    end
  end
end
