defmodule Helix.Websocket.Utils do

  def no_reply(socket),
    do: {:noreply, socket}

  def reply_ok(data = %{data: _}, socket),
    do: {:reply, {:ok, data}, socket}
  def reply_ok(data, socket),
    do: reply_ok(%{data: data}, socket)

  def reply_error(msg, socket) when is_binary(msg),
    do: reply_error(%{data: %{message: msg}}, socket)
  def reply_error(error = %{message: _}, socket),
    do: {:reply, {:error, %{data: error}}, socket}
  def reply_error(error = %{data: _}, socket),
    do: {:reply, {:error, error}, socket}

  def internal_error(socket),
    do: reply_error("internal", socket)
end
