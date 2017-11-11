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

  defmacro reply_error(data, ready: true) do
    quote do
      {:error, %{__ready__: unquote(data)}}
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

  @type input_element ::
    :password
    | :hostname

  @spec validate_input(unsafe_input :: String.t, input_element, opts :: []) ::
    {:ok, validated_input :: String.t}
    | :bad_request
  @doc """
  This is a generic function meant to validate external input that does not
  conform to a specific shape or format (like internal IDs or IP addresses).

  The `element` argument identifies what the input is supposed to represent, and
  we leverage this information to customize the validation for different kinds
  of input.

  TODO: This function should be somewhere else, since it may be re-used by other
  modules, including Models doing "pure" verification.
  """
  def validate_input(input, :password, _) do
    {:ok, input}  # Validation itself is also TODO :-)
  end

  def validate_input(input, :hostname, _),
    do: validate_hostname(input)

  defp validate_hostname(v) when not is_binary(v),
    do: :bad_request
  defp validate_hostname(v),
    do: {:ok, v}
end
