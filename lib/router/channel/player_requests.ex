defmodule Helix.Router.Channel.PlayerRequests do

  use Phoenix.Channel

  alias Helix.Account.WS.Routes, as: Account

  def join(_topic, _message, socket) do
    # God in the command
    {:ok, socket}
  end

  def handle_in(topic = "account." <> _, params, socket) do
    Account.handle_in(topic, params, socket)
  end

  def handle_in(_, _, socket) do
    {:reply, :error, socket}
  end
end
