defmodule Helix.Account.Controller.AccountSetting do

  alias Helix.Account.Model.Account
  alias Helix.Account.Model.AccountSetting
  alias Helix.Account.Model.Setting
  alias Helix.Account.Repo

  @spec put(Account.t, Setting.id, String.t) ::
    {:ok, String.t}
    | {:error, Ecto.Changeset.t}
  def put(account, setting_id, setting_value) do
    params = %{
      account_id: account.account_id,
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

  @spec get(Account.t, Setting.id) :: {:ok, String.t} | {:error, :notfound}
  def get(account, setting_id) do
    account_setting =
      account.account_id
      |> AccountSetting.Query.by_account_id()
      |> AccountSetting.Query.by_setting_id(setting_id)
      |> Repo.one()

    if account_setting != nil do
      {:ok, account_setting.setting_value}
    else
      setting =
        setting_id
        |> Setting.Query.by_id()
        |> Repo.one()

      if setting != nil do
        {:ok, setting.default_value}
      else
        {:error, :notfound}
      end
    end
  end

  @spec get_settings(Account.t) :: %{Setting.id => String.t}
  def get_settings(account) do
    default_settings =
      Setting.Query.select_setting_id_and_default_value()
      |> Repo.all()
      |> :maps.from_list()

    custom_settings =
      account.account_id
      |> AccountSetting.Query.by_account_id()
      |> AccountSetting.Query.select_setting_id_and_setting_value()
      |> Repo.all()
      |> :maps.from_list()

    Map.merge(default_settings, custom_settings)
  end
end