defmodule Helix.Websocket.Request.Proxy do
  @moduledoc """
  A `Request.Proxy` acts exactly like a proxy: it acts as a frontend for the
  Client (public-facing API) and will dispatch the request to the underlying
  backend, chosen at `select_backend/2`.

  This is totally transparent to the Client.
  """

  import Helix.Websocket.Request

  alias Helix.Websocket
  alias Helix.Websocket.Request

  @doc """
  Selects which backend should handle the proxy request.

  An `{:ok, module}` return means that the request should be dispatched to
  `module`. On the other hand, returning `{:error, reason}` means the request
  should fail immediately with `reason`.
  """
  defmacro select_backend(request, socket, do: block)  do
    quote do

      @spec select_backend(Request.t, Websocket.socket) ::
        {:ok, Request.t}
        | {:error, reason :: atom | String.t}
      def select_backend(unquote(request), unquote(socket)) do
        unquote(block)
      end

    end
  end

  @doc """
  ProxyRequest will dispatch the request to the chosen backend.

  Methods implementing `proxy_request` must implement `select_backend/2`.
  """
  defmacro proxy_request(name, do: block) do
    quote location: :keep do

      request unquote(name) do

        alias Helix.Websocket.Requestable

        @doc false
        def check_params(request, socket) do
          request
          |> select_backend(socket)
          |> handle_backend(request, socket)
        end

        defp handle_backend({:ok, backend}, request, socket) do
          sub_request =
            backend
            |> apply(:new, [request.unsafe, socket])
            |> Map.replace(:relay, request.relay)

          with {:ok, req} <- Requestable.check_params(sub_request, socket) do
            update_meta(request, %{sub_request: req}, reply: true)
          end
        end

        defp handle_backend({:error, reason}, request, _socket),
          do: reply_error(request, reason)

        @doc false
        def check_permissions(request, socket) do
          sub_request = request.meta.sub_request

          with \
            {:ok, req} <- Requestable.check_permissions(sub_request, socket)
          do
            update_meta(request, %{sub_request: req}, reply: true)
          end
        end

        @doc false
        def handle_request(request, socket) do
          sub_request = request.meta.sub_request

          with \
            {:ok, req} <- Requestable.handle_request(sub_request, socket)
          do
            update_meta(request, %{sub_request: req}, reply: true)
          end
        end

        unquote(block)

        # Fallbacks to the backend request reply
        @doc false
        def reply(request, socket) do
          sub_request = request.meta.sub_request

          Requestable.reply(sub_request, socket)
        end
      end

    end
  end
end
