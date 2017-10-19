defmodule Helix.Websocket.Flow do
  @moduledoc """
  ChannelFlow are common macros used by both `Helix.Websocket.Request` and
  `Helix.Websocket.Join`.
  """

  @doc """
  Interrupts the Request/Join flow with an error message.

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
  Proceeds with the Request/Join flow by signaling everything is OK.
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
end
