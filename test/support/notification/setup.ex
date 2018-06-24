defmodule Helix.Test.Notification.Setup do

  alias Ecto.Changeset
  alias Helix.Notification.Model.Notification
  alias Helix.Notification.Repo, as: NotificationRepo

  alias Helix.Test.Account.Helper, as: AccountHelper
  alias Helix.Test.Server.Helper, as: ServerHelper

  @classes [:account, :server]
  @code_map %{
    account: [:server_password_acquired],
    server: [:file_downloaded]
  }

  @doc """
  See docs on `fake_notification/1`.
  """
  def notification(opts \\ []) do
    {changeset, related} = fake_notification(opts)
    db_entry = NotificationRepo.insert!(changeset)
    {db_entry, related}
  end

  def notification!(opts \\ []) do
    {entry, _} = notification(opts)
    entry
  end

  @doc """
  Opts:
  - class: Set notification class. Defaults to random class.
  - code: Set notification code. Defaults to random code within `class`.
  - data: Set notification data. Generates valid data and extra for
    `{class, code}` by default.
  - account_id: Specify notification owner account id. Defaults to random
    account id. Ignored if `id_map` is specified.
  - id_map: ID map that should be used by the notification creation method.
    If not set, generates the required data.
  - extra: Extra params used by the notification. Defaults to empty map, and it
    is ignored when `data` is not set.
  - is_read: Whether the notification should be marked as read. Defaults to
    false
  """
  def fake_notification(opts) do
    class = Keyword.get(opts, :class, random_class())
    {_, code} = Keyword.get(opts, :code, random_code(class))

    {data, extra} =
      if opts[:data] do
        {opts[:data], opts[:extra] || %{}}
      else
        generate_data(class, code)
      end

    account_id = Keyword.get(opts, :account_id, AccountHelper.id())
    id_map = Keyword.get(opts, :id_map, generate_id_map(class, account_id))

    changeset = Notification.create_changeset(class, code, data, id_map, extra)

    changeset =
      if opts[:is_read] do
        Changeset.put_change(changeset, :is_read, true)
      else
        changeset
      end

    related =
      %{
        changeset: changeset,
        class: class,
        code: code,
        id_map: id_map,
        data: data,
        extra: extra
      }

    {changeset, related}
  end

  @doc """
  Generates a valid (but fake) notification `data` and `extra` for the given
  `{class, code}` tuple.
  """
  def generate_data(class, code),
    do: __MODULE__.Data.generate(class, code)

  @doc """
  Generates a valid (but fake) id_map for the given `class`.
  """
  def generate_id_map(class),
    do: generate_id_map(class, AccountHelper.id())
  def generate_id_map(:account, account_id),
    do: %{account_id: account_id}
  def generate_id_map(:server, account_id) do
    %{
      server_id: ServerHelper.id(),
      account_id: account_id
    }
  end

  @doc """
  Returns a valid random code for the given class.
  """
  def random_code,
    do: random_code(random_class())

  def random_code(class),
    do: {class, Enum.random(@code_map[class])}

  @doc """
  Returns a valid random class.
  """
  def random_class,
    do: Enum.random(@classes)
end
