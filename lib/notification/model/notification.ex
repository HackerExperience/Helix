defmodule Helix.Notification.Model.Notification do
  @moduledoc """
  `Notification` acts as a top-level model to other notifications, dispatching
  any calls to the underlying specialization, defined by `class`.
  """

  import Helix.Core.Validator.Model

  alias Ecto.Queryable
  alias Ecto.Changeset
  alias HELL.MapUtils
  alias Helix.Notification.Model.Code, as: NotificationCode
  alias Helix.Notification.Model.Notification
  alias __MODULE__

  @type id ::
    Notification.Account.id
    | Notification.Server.id

  @type t ::
    Notification.Account.t
    | Notification.Server.t

  @type changeset ::
    Notification.Account.changeset
    | Notification.Server.changeset

  @type class :: :account | :server | :chat | :clan
  @type code :: atom
  @type data :: map

  @type id_map ::
    Notification.Account.id_map
    | Notification.Server.id_map

  @typep id_map_input ::
    Notification.Account.id_map_input
    | Notification.Server.id_map_input

  @typep query_method ::
    Notification.Account.Query.methods
    | Notification.Server.Query.methods

  @typep order_method ::
    Notification.Account.Order.methods
    | Notification.Server.Order.methods

  @spec cast_id(tuple) ::
    {:ok, id}
    | :error
  @doc """
  Given a non-specialized Helix ID (inet-tuple format), return the underlying
  notification ID.
  """
  def cast_id(id = {80, 1, _, _, _, _, _, _}),
    do: Notification.Account.ID.cast(id)
  def cast_id(id = {80, 2, _, _, _, _, _, _}),
    do: Notification.Server.ID.cast(id)
  def cast_id(_),
    do: :error

  @spec cast_id!(tuple) ::
    id
    | no_return
  def cast_id!(id) when is_tuple(id) do
    {:ok, casted_id} = cast_id(id)
    casted_id
  end

  @spec get_class(id | t) ::
    class
  @doc """
  Given a notification (struct or id), return its `class`.
  """
  def get_class(%Notification.Account{}),
    do: :account
  def get_class(%Notification.Account.ID{}),
    do: :account
  def get_class(%Notification.Server{}),
    do: :server
  def get_class(%Notification.Server.ID{}),
    do: :server

  @spec format(t) ::
    t
  @doc """
  Formats the arbitrary data map from DB JSONB to internal Helix format.
  """
  def format(notification = %_{code: code}) do
    class = get_class(notification.notification_id)
    data = MapUtils.atomize_keys(notification.data)

    %{notification|
      data: NotificationCode.after_read_hook(class, code, data)
    }
  end

  @spec create_changeset(class, code, data, id_map, map) ::
    changeset
  @doc """
  Creates a changeset for the given `class`.
  """
  def create_changeset(class, code, data, ids, extra) do
    params =
      %{
        code: code,
        data: data,
      }
      |> Map.merge(ids)
      |> Map.merge(extra)

    dispatch(class, :create_changeset, params)
  end

  @spec mark_as_read(Notification.t) ::
    Notification.changeset
  @doc """
  Marks a notification as read.
  """
  def mark_as_read(notification = %_{notification_id: _}) do
    notification
    |> Changeset.change()
    |> Changeset.put_change(:is_read, true)
  end

  @spec get_id_map(class, id_map_input) ::
    id_map
  @doc """
  `get_id_map/2` returns ids required by `create_changeset/5` to correctly
  create the changeset for the given `class`.

  `id_map_input` is derived from `Notificable.whom_to_notify/1`, at the
  NotificationHandler.
  """
  def get_id_map(class, id_map_input),
    do: dispatch(class, :id_map, id_map_input)

  @spec query(Queryable.t | class, query_method) ::
    Queryable.t
  @doc """
  `query/2` proxies the call to the Query module of the underlying `class`.

  It may receive another `Queryable.t`, in which case it automatically detects
  the underlying class module, as well as appends the Queryable to the args,
  since the given Queryable should be used as a building block to the next one.
  """
  def query(class, query_method),
    do: query(class, query_method, [])
  def query(class, query_method, arg) when not is_list(arg),
    do: query(class, query_method, [arg])
  def query(queryable = %_{from: {_, module}}, query_method, args),
    do: do_query(module, query_method, [queryable | args])
  def query(class, query_method, args) when is_atom(class) do
    class
    |> get_module()
    |> do_query(query_method, args)
  end

  @spec order(Queryable.t, order_method) ::
    Queryable.t
  @doc """
  Similar to `query/2,3`, but executes an `.Order` method instead.

  Must always receive a `Queryable` as input.
  """
  def order(queryable = %_{from: {_, module}}, order_method) do
    module
    |> Module.concat(:Order)
    |> apply(order_method, [queryable])
  end

  @spec valid_class?(atom) ::
    boolean
  @doc """
  Checks whether the given atom represents a valid class
  """
  def valid_class?(:account),
    do: true
  def valid_class?(:server),
    do: true
  def valid_class?(_),
    do: false

  @spec do_query(module :: atom, query_method, list) ::
    Queryable.t
  defp do_query(module, query_method, args) do
    module
    |> Module.concat(:Query)
    |> apply(query_method, args)
  end

  defp dispatch(class, function, arg) when not is_list(arg),
    do: dispatch(class, function, [arg])
  defp dispatch(class, function, args) do
    class
    |> get_module()
    |> apply(function, args)
  end

  @spec get_module(class) ::
    module :: atom
  defp get_module(:account),
    do: __MODULE__.Account
  defp get_module(:server),
    do: __MODULE__.Server

  validator do
    @moduledoc """
    Implementations for `Helix.Core.Validator`
    """

    alias HELL.IPv6

    @type validated_inputs ::
      Notification.id

    @spec validate_id(String.t, opts :: term) ::
      {:ok, Notification.id}
      | :error
    @doc """
    Validates (and converts) the given string into a notification ID.

    It must be:
    - a string
    - with an inet format
    - with a valid suffix
    """
    def validate_id(str_id, _) when is_binary(str_id) do
      with \
        {:ok, tuple_id} <- IPv6.binary_to_address_tuple(str_id),
        {:ok, notification_id} <- Notification.cast_id(tuple_id)
      do
        {:ok, notification_id}
      else
        _ ->
          :error
      end
    end

    def validate_id(_, _),
      do: :error
  end
end
