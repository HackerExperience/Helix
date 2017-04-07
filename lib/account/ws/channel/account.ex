defmodule Helix.Account.WS.Channel.AccountPublic do

  use Phoenix.Channel

  alias Helix.Account.Service.API.Account, as: API

  def join("account:" <> _account_id, _, socket) do
    # God in the command
    {:ok, socket}
  end

  def handle_in(
    "login",
    %{"username" => username, "password" => password},
    socket)
  do
    case API.login(username, password) do
      {:ok, jwt} ->
        {:reply, %{status: :ok, msg: jwt}, socket}
      {:error, :notfound} ->
        {:reply, %{status: :error, msg: "invalid user/pass"}, socket}
    end
  end
end
