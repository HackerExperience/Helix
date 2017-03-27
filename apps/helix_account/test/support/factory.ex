defmodule Helix.Account.Factory do

  use ExMachina.Ecto, repo: Helix.Account.Repo

  alias Comeonin.Bcrypt
  alias HELL.TestHelper.Random
  alias Helix.Account.Model.Account
  alias Helix.Account.Model.AccountSetting
  alias Helix.Account.Model.Setting

  def account_factory do
    display_name = Random.username()
    username = String.downcase(display_name)

    %Account{
      username: display_name,
      display_name: username,
      email: Burette.Internet.email(),
      password: Bcrypt.hashpwsalt(Burette.Internet.password())
    }
  end

  def account_setting_factory do
    settings =
      :setting
      |> build()
      |> Map.from_struct()

    %AccountSetting{
      account: build(:account),
      settings: settings
    }
  end

  def setting_factory do
    %Setting{is_beta: true}
  end
end
