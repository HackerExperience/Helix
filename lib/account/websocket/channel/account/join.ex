defmodule Helix.Account.Websocket.Channel.Account.Join do
  @moduledoc """
  Joinable implementation for the Account channel.

  There's only one way to subscribe to an account's channel, and only the owner
  of the account (authenticated on the Socket) can join this channel.

  Therefore, the requested account_id (specified on the Channel's topic) must
  belong to the authenticated user on the socket.
  """

  require Helix.Websocket.Join

  Helix.Websocket.Join.register()

  defimpl Helix.Websocket.Joinable do

    alias Helix.Account.Model.Account

    def check_params(request, _socket) do
      account_id = get_id_from_topic(request.topic)

      with {:ok, account_id} <- Account.ID.cast(account_id) do
        params = %{
          account_id: account_id
        }

        {:ok, %{request| params: params}}
      else
        _ ->
          {:error, %{message: "bad_request"}}
      end
    end

    @doc """
    This is where we check the requested account is the same one currently
    authenticated.
    """
    def check_permissions(request, socket) do
      account_id = socket.assigns.account.account_id

      if account_id == request.params.account_id do
        {:ok, request}
      else
        {:error, %{message: "access_denied"}}
      end
    end

    def join(_request, socket, _assign),
      do: {:ok, socket}

    defp get_id_from_topic(topic),
      do: List.last(String.split(topic, "account:"))
  end
end
