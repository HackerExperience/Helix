defmodule Helix.Notification.Model.Notification do

  alias HELL.MapUtils
  alias Helix.Notification.Model.Code, as: NotificationCode
  alias Helix.Notification.Model.Notification.Account
  alias __MODULE__

  @type class :: :account | :server | :chat | :clan

  def cast_id(id = {80, 1, _, _, _, _, _, _}),
    do: Notification.Account.ID.cast!(id)
  def cast_id(id = {80, 2, _, _, _, _, _, _}),
    do: Notification.Server.ID.cast!(id)

  def get_class(%Notification.Account{}),
    do: :account
  def get_class(%Notification.Account.ID{}),
    do: :account
  def get_class(%Notification.Server{}),
    do: :server
  def get_class(%Notification.Server.ID{}),
    do: :server

  def format(notification = %_{code: code}) do
    class = get_class(notification.notification_id)
    data = MapUtils.atomize_keys(notification.data)

    %{notification|
      data: NotificationCode.after_read_hook(class, code, data)
    }
  end

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

  def get_notification_map(class, whom_to_notify),
    do: dispatch(class, :notification_map, whom_to_notify)

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

  defp dispatch(class, function),
    do: dispatch(class, function, [])
  defp dispatch(class, function, arg) when not is_list(arg),
    do: dispatch(class, function, [arg])
  defp dispatch(class, function, args) do
    class
    |> get_module()
    |> apply(function, args)
  end

  defp get_module(:account),
    do: __MODULE__.Account
  defp get_module(:server),
    do: __MODULE__.Server
end
