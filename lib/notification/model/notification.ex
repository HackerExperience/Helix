defmodule Helix.Notification.Model.Notification do

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

  @spec cast_id(tuple) ::
    id
  def cast_id(id = {80, 1, _, _, _, _, _, _}),
    do: Notification.Account.ID.cast!(id)
  def cast_id(id = {80, 2, _, _, _, _, _, _}),
    do: Notification.Server.ID.cast!(id)

  @spec get_class(id | t) ::
    class
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
  def format(notification = %_{code: code}) do
    class = get_class(notification.notification_id)
    data = MapUtils.atomize_keys(notification.data)

    %{notification|
      data: NotificationCode.after_read_hook(class, code, data)
    }
  end

  @spec create_changeset(class, code, data, map, map) ::
    changeset
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

  @spec get_id_map(class, id_map_input) ::
    id_map
  def get_id_map(class, id_map_input),
    do: dispatch(class, :id_map, id_map_input)

  @spec query(class, query_method) ::
    Ecto.Queryable.t
  def query(class, query_method),
    do: query(class, query_method, [])
  def query(class, query_method, arg) when not is_list(arg),
    do: query(class, query_method, [arg])
  def query(class, query_method, args) do
    class
    |> get_module()
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
end
