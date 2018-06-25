import Helix.Websocket.Request

request Helix.Notification.Websocket.Requests.Read.All do
  @moduledoc """
  `NotificationReadAllRequest` is called when the player wants to mark as read
  all notifications from a given class.
  """

  import HELL.Macros

  alias Helix.Account.Model.Account
  alias Helix.Notification.Model.Notification
  alias Helix.Notification.Public.Notification, as: NotificationPublic

  def check_params(request, _socket) do
    with \
      {:ok, _} <- ensure_binary(request.unsafe["class"]),
      {:ok, class} <- cast_existing_atom(request.unsafe["class"]),
      true <- Notification.valid_class?(class) || :bad_class
    do
      params = %{class: class}

      update_params(request, params, reply: true)
    else
      {:error, :atom_not_found} ->
        reply_error(request, :bad_class)

      :bad_class ->
        reply_error(request, :bad_class)

      _ ->
        bad_request(request)
    end
  end

  def check_permissions(request, socket) do
    entity_id = socket.assigns.entity_id
    account_id = Account.ID.cast!(to_string(entity_id))

    meta = %{account_id: account_id}

    update_meta(request, meta, reply: true)
  end

  def handle_request(request, _socket) do
    class = request.params.class
    account_id = request.meta.account_id

    hespawn fn ->
      NotificationPublic.mark_as_read(class, account_id)
    end

    reply_ok(request)
  end

  render_empty()
end
