defmodule Helix.Notification.Internal.Notification do

  alias Helix.Account.Model.Account
  alias Helix.Notification.Model.Notification
  alias Helix.Notification.Repo

  @type custom_method :: :by_account_and_server

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
    result =
      class
      |> Notification.query(:by_id, notification_id)
      |> Repo.one()

    with %{} <- result do
      Notification.format(result)
    end
  end

  @spec get_by_account(Notification.class, Account.id) ::
    [Notification.t]
  @doc """
  Queries the underlying `class` based on the recipient `account_id`.
  """
  def get_by_account(class, account_id) do
    class
    |> Notification.query(:by_account, account_id)
    |> Notification.order(:by_newest)
    |> Repo.all()
    |> Enum.map(&Notification.format/1)
  end

  @spec get_custom(custom_method, tuple) ::
    [Notification.t]
  @doc """
  Queries sub-models with custom methods.

  - `by_account_and_server`: queries `Notification.Server` for all notifications
    that belong to the given `account_id` and `server_id`.
  """
  def get_custom(:by_account_and_server, {account_id, server_id}) do
    :server
    |> Notification.query(:by_account, account_id)
    |> Notification.query(:by_server, server_id)
    |> Notification.order(:by_newest)
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
  @doc """
  Inserts a notification into the DB.
  """
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
  def mark_as_read(class, account_id = %Account.ID{}) do
    class
    |> Notification.query(:by_account, account_id)
    |> Repo.update_all(set: [is_read: true])

    :ok
  end
end
