defmodule Helix.Notification.Internal.Notification do

  alias Helix.Account.Model.Account
  alias Helix.Notification.Model.Notification
  alias Helix.Notification.Repo

  @spec fetch(Notification.class, Notification.id) ::
    Notification.t
    | nil
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
end
