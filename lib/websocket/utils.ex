defmodule Helix.Websocket.Utils do

  alias HELL.Utils
  alias Helix.Websocket
  alias Helix.Process.Model.Process
  alias Helix.Process.Public.View.Process, as: ProcessView

  @spec render_process(Process.t, Websocket.t) ::
    %{data: map}
  @doc """
  Helper that automatically renders the reply with the recently created process.
  """
  def render_process(process = %Process{}, socket) do
    process_data = process.data
    server_id = socket.assigns.gateway.server_id
    entity_id = socket.assigns.entity_id

    ProcessView.render(process_data, process, server_id, entity_id)
  end

  @spec reply_ok(Websocket.payload, Websocket.t) ::
    Websocket.reply_ok
  def reply_ok(payload, socket),
    do: {:reply, {:ok, payload}, socket}

  @spec reply_error(Websocket.payload, Websocket.t) ::
    Websocket.reply_error
  def reply_error(payload, socket),
    do: {:reply, {:error, payload}, socket}

  @spec stop(term, Websocket.t) ::
    Websocket.reply_stop
  def stop(reason, socket),
    do: {:stop, reason, socket}

  @spec no_reply(Websocket.t) ::
    Websocket.no_reply
  def no_reply(socket),
    do: {:noreply, socket}

  @spec wrap_data(data) ::
    data
    | %{:data => data}
    when data: map
  def wrap_data(data = %{data: _}),
    do: data
  def wrap_data(data),
    do: %{data: data}

  @spec reply_internal_error(Websocket.t) ::
    Websocket.reply_error
  def reply_internal_error(socket),
    do: reply_error(%{data: %{message: "internal"}}, socket)

  @doc """
  General purpose error code translator. If you want to specify or handle a
  custom return for the errors below, make sure to add a pattern match before
  calling this function. For an example, see FileDownloadRequest.

  Most common translation pattern: {:error, :reason} => "error_reason".

  For instance, {:storage, :full} or {:server, :not_found} are translated to
  "storage_full" and "server_not_found", respectively.
  """
  def get_error(msg) when is_binary(msg),
    do: msg
  def get_error(:internal),
    do: "internal"
  def get_error({a, b}),
    do: Utils.concat(a, "_", b)
end
