defmodule Helix.Account.WS.Channel.Public.Account do

  use Phoenix.Channel

  alias Helix.Account.Service.API.Account, as: API

  def join(_topic, _message, socket) do
    # God in the command
    {:ok, socket}
  end

  def handle_in(
    "login",
    %{"username" => username, "password" => password},
    socket
  ) do
    case API.login(username, password) do
      {:ok, jwt} ->
        response = %{msg: jwt}
        {:reply, {:ok, response}, socket}
      {:error, :notfound} ->
        response = %{msg: "invalid user/pass"}
        {:reply, {:error, response}, socket}
    end
  end

  def handle_in(_, _, socket) do
    {:reply, :error, socket}
  end
end
