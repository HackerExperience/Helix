defmodule Helix.Websocket.Request.Relay do
  @moduledoc """
  `RequestRelay` is a struct intended to be relayed all the way from the Request
  to the Public to the ActionFlow, so it can be used by `Helix.Event` to
  identify the `request_id` and create a meaningful stacktrace.
  """

  alias Helix.Websocket

  defstruct [:request_id, :account_id, :type, :topic]

  @type t :: t_of_type(binary)

  @type t_of_type(type) ::
    %__MODULE__{
      request_id: type,
      account_id: term,
      topic: String.t,
      type: :request | :join
    }

  @spec new(map, Websocket.socket | term, term) ::
    t
    | t_of_type(nil)
  def new(params, socket, request_module \\ nil) do
    request_id = get_request_id(params)
    {req_type, topic, account_id} = get_request_data(socket, request_module)

    %__MODULE__{
      request_id: request_id,
      account_id: account_id,
      type: req_type,
      topic: topic
    }
  end

  defp get_request_id(%{"request_id" => request_id}) when is_binary(request_id),
    do: request_id
  defp get_request_id(_),
    do: nil

  defp get_request_data(nil, _),
    do: {nil, nil, nil}
  defp get_request_data(socket, request_module) do
    topic = get_topic(request_module)
    account_id = socket.assigns.account_id

    req_type =
      if socket.joined do
        :request
      else
        :join
      end

    {req_type, topic, account_id}
  end

  defp get_topic(nil),
    do: "undefined"
  defp get_topic(module) do
    split = Module.split(module)

    service =
      split
      |> Enum.fetch!(1)
      |> String.downcase()

    request =
      split
      |> Enum.fetch!(-1)
      |> String.downcase()

    service <> "." <> request
  end
end
