defmodule Helix.Websocket.Channel do
  @moduledoc """
  Macros for Phoenix Channels.

  For example of usage, see `lib/server/websocket/channel/server.ex`.
  """

  alias Helix.Websocket

  @doc """
  Top-level macro for Channels. Pure syntactic sugar.
  """
  defmacro channel(name, do: block) do
    quote do

      defmodule unquote(name) do

        use Phoenix.Channel, log_join: false, log_handle_in: false

        unquote(block)
      end

    end
  end

  @doc """
  Macro for defining a topic that should be handled by the Channel. It must
  specify both the topic name (which will be used to listen to incoming
  messages) and the corresponding request handler. The request handler must
  implement the Requestable protocol. See `Helix.Websocket.Request`.
  """
  defmacro topic(name, request) do
    quote do

      def handle_in(unquote(name), params, socket) do
        unquote(request).new(params, socket)
        |> Websocket.handle_request(socket)
      end

    end
  end

  @doc """
  Macro for topics intended to join the channel. It must specify both the topic
  name (which may be a wildcard, in which case all join requests get through)
  and the corresponding join handler. The join handler must implement the
  Joinable protocol. See `Helix.Websocket.Join`.
  """
  defmacro join(name, join_handler) do
    quote do

      def join(topic = unquote(name), params, socket) do
        unquote(join_handler).new(topic, params, socket)
        |> Websocket.handle_join(socket, &assign/3)
      end

    end
  end

  @doc """
  Macro used to intercept and handle outgoing events. Handling of events is
  done through the Notificable.Flow implemented at Helix.Websocket.
  """
  defmacro event_handler(name) do
    quote do

      intercept [unquote(name)]

      def handle_out(unquote(name), event, socket) do
        Websocket.handle_event(event, socket, &push/3)
      end

    end
  end
end
