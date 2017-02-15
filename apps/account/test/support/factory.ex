defmodule Helix.Account.Factory do

  use ExMachina.Ecto, repo: Helix.Account.Repo

  alias HELL.PK
  alias HELL.TestHelper.Random
  alias Helix.Account.Model.Account
  alias Helix.Account.Model.AccountSetting
  alias Helix.Account.Model.Setting

  def params(:account) do
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
    setting_id =
      [min: 20, max: 20]
      |> Random.string()
      |> String.downcase()

    %Setting{
      setting_id: setting_id,
      default_value: Random.string()
    }
  end

  def account_setting_factory do
    %AccountSetting{
      account: build(:account),
      setting: build(:setting),
      setting_value: Random.string()
    }
  end
end