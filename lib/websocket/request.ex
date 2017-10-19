defmodule Helix.Websocket.Request do
  @moduledoc """
  `WebsocketRequest` is a generic data type that represents any Channel request
  that is handled by `Requestable`.

  A module that wants to process channel requests should:

  - Register itself as a request (`Request.register()`)
  - Implement the Requestable protocol

  For usage example, see `lib/server/websocket/server/requests/bruteforce.ex`
  and `lib/software/websocket/requests/pftp/server/enable.ex`
  """

  import HELL.Macros

  alias Helix.Websocket.Utils, as: WebsocketUtils

  @type t(struct) :: %{
    __struct__: struct,
    unsafe: map,
    params: map,
    meta: map
  }

  @doc """
  Top-level macro for creating a Websocket Request, which can be handled by any
  channel. It must implement the Requestable protocol.
  """
  defmacro request(name, do: block) do
    quote do

      defmodule unquote(name) do
        @moduledoc false

        import Helix.Websocket.Flow

        @type t :: Helix.Websocket.Request.t(__MODULE__)

        @enforce_keys [:unsafe]
        defstruct [:unsafe, params: %{}, meta: %{}]

        @spec new(term) ::
          t
        def new(params \\ %{}) do
          %__MODULE__{
            unsafe: params
          }
        end

        defimpl Helix.Websocket.Requestable do
          @moduledoc false

          unquote(block)

          docp """
          Fallbacks to WebsocketUtils' general purpose error code translator.
          """
          defp get_error(error),
            do: WebsocketUtils.get_error(error)
        end
      end

    end
  end

  @doc """
  Macro used to render the output that will be sent to the client. It's simply a
  wrapper to `Requestable.reply/2`. The advantage of wrapping it through this
  macro, though, is that we can apply system-wide patches/parsers if/when the
  time comes.
  """
  defmacro render(request, socket, do: block) do
    quote do

      def reply(unquote(request), unquote(socket)) do
        unquote(block)
      end

    end
  end

  @doc """
  Shorthand for requests that render a process as response. It assumes the
  process is at the Request meta field, under the `process` key
  """
  defmacro render_process do
    quote do

      def reply(request, socket) do
        {:ok, WebsocketUtils.render_process(request.meta.process, socket)}
      end

    end
  end

  @doc """
  Shorthand for requests that want to reply with an empty data field. In these
  cases, all the client gets is a successful return code.
  """
  defmacro render_empty do
    quote do

      def reply(_, _) do
        {:ok, %{}}
      end

    end
  end
end
