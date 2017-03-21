defmodule Helix.Account.Controller.AccountSetting do

  alias Helix.Account.Model.Account
  alias Helix.Account.Model.AccountSetting
  alias Helix.Account.Model.Setting
  alias Helix.Account.Repo

  import Ecto.Query, only: [select: 3]

  @spec put(Account.t | Account.id, Setting.t | Setting.id, String.t) ::
    {:ok, String.t} | {:error, Ecto.Changeset.t}
  def put(account = %Account{}, setting, setting_value),
    do: put(account.account_id, setting, setting_value)
  def put(account, setting = %Setting{}, setting_value),
    do: put(account, setting.setting_id, setting_value)
  def put(account_id, setting_id, setting_value) do
    params = %{
      account_id: account_id,
      setting_id: setting_id,
      setting_value: setting_value
    }

    result =
      params
      |> AccountSetting.create_changeset()
      |> Repo.insert_or_update()

    case result do
      {:ok, account_setting} ->
        {:ok, account_setting.setting_value}
      {:error, error} ->
        {:error, error}
    end
  end

  @spec get(Account.t | Account.id, Setting.t | Setting.id) ::
    {:ok, String.t}
    | {:error, :notfound}
  def get(account, setting = %Setting{}),
    do: get(account, setting.setting_id)
  def get(account, setting_id) do
    account_setting =
      account
      |> AccountSetting.Query.from_account()
      |> AccountSetting.Query.from_setting(setting_id)
      |> Repo.one()

    if account_setting do
      {:ok, account_setting.setting_value}
    else
      default =
        setting_id
        |> Setting.Query.by_id()
        |> Repo.one()

      if default do
        {:ok, default.default_value}
      else
        {:error, :notfound}
      end
    end
  end

  @spec get_settings(Account.t | Account.id) :: %{Setting.id => String.t}
  def get_settings(account) do
    default_settings =
      Setting
      |> select([s], {s.setting_id, s.default_value})
      |> Repo.all()
      |> :maps.from_list()

    custom_settings =
      account.account_id
      |> AccountSetting.Query.from_account()
      |> select([as], {as.setting_id, as.setting_value})
      |> Repo.all()
      |> :maps.from_list()

    Map.merge(default_settings, custom_settings)
  end
end