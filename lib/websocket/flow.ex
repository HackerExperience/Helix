defmodule Helix.Websocket.Flow do
  @moduledoc """
  Common macros used by `Helix.Websocket.Request` and `Helix.Websocket.Join`.
  """

  alias Helix.Websocket.Flow.Utils, as: FlowUtils

  @doc """
  Interrupts the Request/Join flow with an error message.

  If the passed message is an atom, we assume it hasn't been translated to the
  external format yet, so we call `get_error/1`.

  If `ready: true` is passed as opts, we assume the error response is already
  formatted and send it without any modification. The `__ready__` flag is used
  internally by `Helix.Websocket` so it knows it is supposed to relay that value
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

  @doc """
  Shorthand for `validate_bounce` from `RequestUtils`.
  """
  defmacro validate_bounce(bounce_id) do
    quote do
      FlowUtils.validate_bounce(unquote(bounce_id))
    end
  end

  @doc """
  Shorthand for `validate_input` from `RequestUtils`.
  """
  defmacro validate_input(input, element, opts \\ quote(do: [])) do
    quote do
      FlowUtils.validate_input(unquote(input), unquote(element), unquote(opts))
    end
  end

  @doc """
  Shorthand for `ensure_type(:binary)` from `RequestUtils`.
  """
  defmacro ensure_binary(input) do
    quote do
      FlowUtils.ensure_type(:binary, unquote(input))
    end
  end

  @doc """
  Helper to cast strings which are expected to already exist as atoms.
  """
  defmacro cast_existing_atom(unsafe_string) do
    quote do
      FlowUtils.cast_existing_atom(unquote(unsafe_string))
    end
  end

  @doc """
  Helper to cast optional parameters, i.e. parameters that may not exist.
  """
  defmacro cast_optional(req, key, cast, default \\ quote(do: {:ok, nil})) do
    quote do
      FlowUtils.cast_optional(
        unquote(req).unsafe, unquote(key), unquote(cast), unquote(default)
      )
    end
  end

  @doc """
  Helper to cast a list of parameters.
  """
  defmacro cast_list_of_ids(elements, cast_function) do
    quote do
      FlowUtils.cast_list_of_ids(unquote(elements), unquote(cast_function))
    end
  end
end

defmodule Helix.Websocket.Flow.Utils do
  @moduledoc """
  Utils for `Helix.Websocket.Flow`
  """

  alias HELL.IPv4
  alias Helix.Core.Validator
  alias Helix.Network.Model.Bounce
  alias Helix.Network.Model.Network

  @spec validate_nip(unsafe :: String.t | Network.id, unsafe_ip :: String.t) ::
    {:ok, Network.id, Network.ip}
    | :bad_request
  @doc """
  Ensures the given nip, which is unsafe (user input), is valid and within the
  expected format.

  NOTE: This function does not check whether the nip exists.
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
    {:ok, Validator.validated_inputs}
    | :bad_request
  @doc """
  Delegates the input validation to `Validator`.
  """
  def validate_input(input, type, opts) do
    case Validator.validate_input(input, type, opts) do
      {:ok, valid_input} ->
        {:ok, valid_input}

      :error ->
        :bad_request
    end
  end

  @spec validate_bounce(unsafe_bounce :: String.t | nil) ::
    {:ok, nil}
    | {:ok, Bounce.id}
    | :bad_request
  @doc """
  Ensures the given bounce is valid. It may either be nil (i.e. no bounce) or 
  a valid Bounce.ID.

  NOTE: This function does not check whether the bounce exists.
  """
  def validate_bounce(nil),
    do: {:ok, nil}
  def validate_bounce(bounce_id) do
    case Bounce.ID.cast(bounce_id) do
      {:ok, bounce_id} ->
        {:ok, bounce_id}

      :error ->
        :bad_request
    end
  end

  @spec cast_existing_atom(String.t) ::
    {:ok, atom}
    | {:error, :atom_not_found}
  @doc """
  Ensures the given string already exists as an atom, and also converts it to an
  atom.
  """
  def cast_existing_atom(unsafe) do
    try do
      atom = String.to_existing_atom(unsafe)
      {:ok, atom}
    rescue
      _ ->
        {:error, :atom_not_found}
    end
  end

  @spec cast_optional(map, binary | atom, function, default :: term) ::
    {:ok, casted :: term}
    | default :: term
  @doc """
  Helper that casts optional parameters, falling back to `default` when they
  have not been specified.
  """
  def cast_optional(unsafe, key, cast_function, default) when is_atom(key),
    do: cast_optional(unsafe, to_string(key), cast_function, default)
  def cast_optional(unsafe, key, cast_function, default) do
    if Map.has_key?(unsafe, key) do
      cast_function.(unsafe[key])
    else
      default
    end
  end

  @spec cast_list_of_ids([unsafe_ids :: term] | nil, function) ::
    {:ok, [casted_ids :: term]}
    | {:bad_id, unsafe_id :: term}
    | :bad_request
  @doc """
  Helper to automatically cast a list of IDs - it applies `cast_fun` to all
  members of `elements`, accumulating the result.

  May return `:bad_request` when input is not a list, or `{:bad_id, unsafe_id}`
  when one of the IDs failed to cast.
  """
  def cast_list_of_ids(elements, _fun) when not is_list(elements),
    do: :bad_request
  def cast_list_of_ids(elements, cast_fun) when is_function(cast_fun) do
    Enum.reduce_while(elements, {:ok, []}, fn unsafe_id, {_, acc} ->
      case cast_fun.(unsafe_id) do
        {:ok, element_id} ->
          {:cont, {:ok, acc ++ [element_id]}}

        :error ->
          {:halt, {:bad_id, unsafe_id}}
      end
    end)
  end

  @spec ensure_type(:binary, String.t) :: {:ok, String.t}
  @spec ensure_type(:binary, list | integer | map) :: :error
  @doc """
  Ensures that the given `input` belongs to the underlying type.
  """
  def ensure_type(:binary, input) when is_binary(input),
    do: {:ok, input}
  def ensure_type(:binary, _),
    do: :error
end
