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

  alias Helix.Websocket.Request.Utils, as: RequestUtils
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
  Interrupts the Request flow with an error message.

  If the passed message is an atom, we assume it hasn't been translated to the
  external format yet, so we call `get_error/1`.
  """
  defmacro reply_error(msg) when is_binary(msg) do
    quote do
      {:error, %{message: unquote(msg)}}
    end
  end

  defmacro reply_error(reason) when is_atom(reason) or is_tuple(reason) do
    quote do
      {:error, %{message: get_error(unquote(reason))}}
    end
  end

  @doc """
  Shorthand for the `bad_request` error.
  """
  defmacro bad_request do
    quote do
      reply_error("bad_request")
    end
  end

  @doc """
  Shorthand for the `internal` error.
  """
  defmacro internal_error do
    quote do
      reply_error("internal")
    end
  end

  @doc """
  Proceeds with the Request flow by signaling everything is OK.
  """
  defmacro reply_ok(request) do
    quote do
      {:ok, unquote(request)}
    end
  end

  @doc """
  Updates the meta field with the given value. If `reply` opt is specified,
  automatically return the expected OK response.
  """
  defmacro update_meta(request, meta, reply: true) do
    quote do
      reply_ok(%{unquote(request)| meta: unquote(meta)})
    end
  end

  defmacro update_meta(request, meta) do
    quote do
      var!(request) = %{unquote(request)| meta: unquote(meta)}
    end
  end

  @doc """
  Updates the params field with the given value. If `reply` opt is specified,
  automatically return the expected OK response.
  """
  defmacro update_params(request, params, reply: true) do
    quote do
      reply_ok(%{unquote(request)| params: unquote(params)})
    end
  end

  defmacro update_params(request, params) do
    quote do
      var!(request) = %{unquote(request)| params: unquote(params)}
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

  defmacro validate_nip(network_id, ip) do
    quote do
      RequestUtils.validate_nip(unquote(network_id), unquote(ip))
    end
  end
end

defmodule Helix.Websocket.Request.Utils do

  alias HELL.IPv4
  alias Helix.Network.Model.Network

  @spec validate_nip(unsafe_network_id :: String.t, unsafe_ip :: String.t) ::
    {:ok, Network.id, IPv4.t}
    | :bad_request
  def validate_nip(unsafe_network_id, unsafe_ip) do
    with \
      {:ok, network_id} <- Network.ID.cast(unsafe_network_id),
      true <- IPv4.valid?(unsafe_ip)
    do
      {:ok, network_id, unsafe_ip}
    else
      _ ->
        :bad_request
    end
  end
end
