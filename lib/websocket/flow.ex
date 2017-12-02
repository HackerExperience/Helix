defmodule Helix.Websocket.Flow do
  @moduledoc """
  ChannelFlow are common macros used by both `Helix.Websocket.Request` and
  `Helix.Websocket.Join`.
  """

  alias Helix.Websocket.Flow.Utils, as: FlowUtils

  @doc """
  Interrupts the Request/Join flow with an error message.

  If the passed message is an atom, we assume it hasn't been translated to the
  external format yet, so we call `get_error/1`.

  If `ready: true` is passed as opts, we assume the error response is already
  formatted and send it without any modification. The `__ready__` flag is used
  internally by `Helix.Websocket` so it knows it's supposed to relay that value
  directly to the client too.
  """
  defmacro reply_error(request, msg) when is_binary(msg) do
    quote do
      {:error, %{message: unquote(msg)}, unquote(request)}
    end
  end

  defmacro reply_error(req, reason) when is_atom(reason) or is_tuple(reason) do
    quote do
      {:error, %{message: get_error(unquote(reason))}, unquote(req)}
    end
  end

  defmacro reply_error(request, data, ready: true) do
    quote do
      {:error, %{__ready__: unquote(data)}, unquote(request)}
    end
  end

  @doc """
  Shorthand for the `bad_request` error.
  """
  defmacro bad_request(request) do
    quote do
      reply_error(unquote(request), "bad_request")
    end
  end

  @doc """
  Shorthand for the `internal` error.
  """
  defmacro internal_error(request) do
    quote do
      reply_error(unquote(request), "internal")
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
      %{unquote(request)| params: unquote(params)}
    end
  end

  @doc """
  Shorthand for `validate_nip` from `RequestUtils`.

  This function does not check whether the nip exists!
  """
  defmacro validate_nip(network_id, ip) do
    quote do
      FlowUtils.validate_nip(unquote(network_id), unquote(ip))
    end
  end

  defmacro validate_input(input, element, opts \\ quote(do: [])) do
    quote do
      FlowUtils.validate_input(unquote(input), unquote(element), unquote(opts))
    end
  end
end

defmodule Helix.Websocket.Flow.Utils do
  @moduledoc """
  Utils for `Helix.Websocket.Flow`
  """

  alias HELL.IPv4
  alias Helix.Core.Validator
  alias Helix.Network.Model.Network

  @spec validate_nip(unsafe :: String.t | Network.id, unsafe_ip :: String.t) ::
    {:ok, Network.id, Network.ip}
    | :bad_request
  @doc """
  Ensures the given nip, which is unsafe (user input), is valid and within the
  expected format.

  This function does not check whether the nip exists!
  """
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

  @spec validate_input(unsafe_input :: String.t, Validator.input_type, term) ::
    {:ok, validated_input :: String.t}
    | :bad_request
  def validate_input(input, type, opts) do
    case Validator.validate_input(input, type, opts) do
      {:ok, valid_input} ->
        {:ok, valid_input}

      :error ->
        :bad_request
    end
  end
end
