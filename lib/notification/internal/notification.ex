defmodule Helix.Notification.Internal.Notification do

  alias Helix.Account.Model.Account
  alias Helix.Notification.Model.Notification
  alias Helix.Notification.Repo

  @typep fetch_result ::
    Notification.t
    | nil

  @spec fetch(Notification.id) ::
    fetch_result
  def fetch(notification_id) do
    notification_id
    |> Notification.get_class()
    |> fetch(notification_id)
  end

  @spec fetch(Notification.class, Notification.id) ::
    fetch_result
  def fetch(class, notification_id) do
    class
    |> Notification.query(:by_id, notification_id)
    |> Repo.one()
    |> Notification.format()
  end

  @spec get_by_account(Notification.class, Account.id) ::
    [Notification.t]
  @doc """
  Queries the underlying `class` based on the recipient `account_id`.
  """
  def get_by_account(class, account_id) do
    class
    |> Notification.query(:by_account, account_id)
    |> Repo.all()
    |> Enum.map(&Notification.format/1)
  end

  @spec add_notification(
    Notification.class,
    Notification.code,
    Notification.data,
    Notification.id_map,
    map
  ) ::
    {:ok, Notification.t}
    | {:error, Notification.changeset}
  def add_notification(class, code, data, id_map, extra_params) do
    class
    |> Notification.create_changeset(code, data, id_map, extra_params)
    |> Repo.insert()
  end

  @spec mark_as_read(Notification.t) ::
    {:ok, Notification.t}
    | {:error, Notification.changeset}
  @doc """
  Marks the given notification as read.
  """
  def mark_as_read(notification = %_{is_read: true}),
    do: {:ok, notification}
  def mark_as_read(notification = %_{}) do
    notification
    |> Notification.mark_as_read()
    |> Repo.update()
  end

  @spec mark_as_read(Notification.class, Account.id) ::
    :ok
  @doc """
  Marks all notifications that belong to `account_id` and `class` as read.
  """
  def mark_as_read(class, account_id) do
    class
    |> Notification.query(:by_account, account_id)
    |> Repo.update_all(set: [is_read: true])

    :ok
  end
end
