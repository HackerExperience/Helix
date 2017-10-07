defmodule Helix.Websocket.Utils do

  alias Helix.Process.Model.Process
  alias Helix.Process.Public.View.Process, as: ProcessView

  @type socket :: term

  @type reply_ok ::
    {:reply, {:ok, term}, socket}

  @type reply_error ::
    {:reply, {:error, %{data: term}}, socket}

  @type no_reply ::
    {:noreply, socket}

  @spec no_reply(socket) ::
    no_reply
  def no_reply(socket),
    do: {:noreply, socket}

  @spec reply_process(Process.t, socket) ::
    reply_ok
  @doc """
  Helper that automatically renders the reply with the recently created process.
  """
  def reply_process(process = %Process{}, socket) do
    process_data = process.process_data
    server_id = socket.assigns.gateway.server_id
    entity_id = socket.assigns.entity_id

    pview = ProcessView.render(process_data, process, server_id, entity_id)

    reply_ok(%{data: pview}, socket)
  end

  @spec reply_ok(term, socket) ::
    reply_ok
  def reply_ok(data = %{data: _}, socket),
    do: {:reply, {:ok, data}, socket}
  def reply_ok(data, socket),
    do: reply_ok(%{data: data}, socket)

  @spec reply_error(term, socket) ::
    reply_error
  def reply_error(msg, socket) when is_binary(msg),
    do: reply_error(%{data: %{message: msg}}, socket)
  def reply_error(error = %{message: _}, socket),
    do: {:reply, {:error, %{data: error}}, socket}
  def reply_error(error = %{data: _}, socket),
    do: {:reply, {:error, error}, socket}

  @spec internal_error(socket) ::
    reply_error
  def internal_error(socket),
    do: reply_error("internal", socket)
end
