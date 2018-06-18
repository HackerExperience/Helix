defmodule Helix.Notification.Internal.Notification do

  alias Helix.Notification.Model.Notification
  alias Helix.Notification.Repo

  def fetch(class, notification_id) do
    class
    |> Notification.query(:by_id, notification_id)
    |> Repo.one()
    |> Notification.format()
  end

  def get_by_account(class, account_id) do
    class
    |> Notification.query(:by_account, account_id)
    |> Repo.all()
    |> Enum.map(&Notification.format/1)
  end

  def add_notification(class, code, data, ids, extra) do
    class
    |> Notification.create_changeset(code, data, ids, extra)
    |> Repo.insert()
  end
end
