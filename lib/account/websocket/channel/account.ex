defmodule Helix.Account.Websocket.Channel.Account do
  @moduledoc """
  Channel to notify an user of an action that affects them.
  """

  use Phoenix.Channel

  alias Helix.Entity.Service.API.HackDatabase
  alias Helix.Entity.Service.API.Entity

  def join("account:" <> account_id, _message, socket) do
    # TODO: Provide a cleaner way to check this

    player_account_id = to_string(socket.assigns.account.account_id)
    if account_id == player_account_id do
      {:ok, socket}
    else
      {:error, %{reason: "can't join another user's notification channel"}}
    end
  end

  def handle_in("hack_database.index", _message, socket) do
    hack_database =
      socket.assigns.account.account_id
      |> Entity.get_entity_id()
      |> HackDatabase.get_database()

    {:reply, {:ok, %{data: %{entries: hack_database}}}, socket}
  end

  def notify(account_id, notification) do
    Helix.Endpoint.broadcast(
      "account:" <> account_id,
      "notification",
      notification)
  end
end
