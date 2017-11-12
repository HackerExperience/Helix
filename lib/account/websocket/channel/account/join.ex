import Helix.Websocket.Join

join Helix.Account.Websocket.Channel.Account.Join do
  @moduledoc """
  Joinable implementation for the Account channel.

  There's only one way to subscribe to an account's channel, and only the owner
  of the account (authenticated on the Socket) can join this channel.

  Therefore, the requested account_id (specified on the Channel's topic) must
  belong to the authenticated user on the socket.
  """

  alias Helix.Websocket.Utils, as: WebsocketUtils
  alias Helix.Client.Public.Client, as: ClientPublic
  alias Helix.Account.Model.Account
  alias Helix.Account.Public.Account, as: AccountPublic

  def check_params(request, _socket) do
    account_id = get_id_from_topic(request.topic)

    with {:ok, account_id} <- Account.ID.cast(account_id) do
      params = %{
        account_id: account_id
      }

      update_params(request, params, reply: true)
    else
      _ ->
        bad_request()
    end
  end

  @doc """
  This is where we check the requested account is the same one currently
  authenticated.
  """
  def check_permissions(request, socket) do
    account_id = socket.assigns.account_id

    if account_id == request.params.account_id do
      reply_ok(request)
    else
      reply_error("access_denied")
    end
  end

  def join(_request, socket, _assign) do
    entity_id = socket.assigns.entity_id
    client = socket.assigns.client

    account_bootstrap =
      entity_id
      |> AccountPublic.bootstrap()
      |> AccountPublic.render_bootstrap()

    client_bootstrap = ClientPublic.bootstrap(client, entity_id)
    client_bootstrap = ClientPublic.render_bootstrap(client, client_bootstrap)

    bootstrap =
      account_bootstrap
      |> Map.merge(client_bootstrap)
      |> WebsocketUtils.wrap_data()

    {:ok, bootstrap, socket}
  end

  defp get_id_from_topic(topic),
    do: List.last(String.split(topic, "account:"))
end
