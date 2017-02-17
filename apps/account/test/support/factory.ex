defmodule Helix.Account.Factory do

  use ExMachina.Ecto, repo: Helix.Account.Repo

  alias HELL.PK
  alias HELL.TestHelper.Random
  alias Helix.Account.Model.Account
  alias Helix.Account.Model.AccountSetting
  alias Helix.Account.Model.Setting

  def params(:setting) do
    %{
      setting_id: setting_id(),
      default_value: setting_value()
    }
  end

  def params(:account_setting) do
    account = insert(:account)
    setting = insert(:setting)

    %{
      account: account,
      account_id: account.account_id,
      setting_id: setting.setting_id,
      setting_value: setting_value()
    }
  end

  def account_factory do
    pk = PK.generate([0x0000, 0x0000, 0x0000])
    display_name = Random.username()
    username = String.downcase(display_name)

    %Account{
      account_id: pk,
      username: display_name,
      display_name: username,
      email: Burette.Internet.email(),
      password: Burette.Internet.password()
    }
  end

  def setting_factory do
    %Setting{
      setting_id: setting_id(),
      default_value: Random.string()
    }
  end

  def account_setting_factory do
    %AccountSetting{
      account: build(:account),
      setting: build(:setting),
      setting_value: setting_value()
    }
  end

  defp setting_id do
    [min: 20, max: 20]
    |> Random.string()
    |> String.downcase()
  end

  defp setting_value,
    do: Random.string()
end