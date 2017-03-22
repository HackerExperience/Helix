defmodule Helix.Account.Factory do

  use ExMachina.Ecto, repo: Helix.Account.Repo

  alias Comeonin.Bcrypt
  alias HELL.TestHelper.Random
  alias Helix.Account.Model.Account
  alias Helix.Account.Model.AccountSetting

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
    settings = %{is_beta: true}

    %AccountSetting{
      account: build(:account),
      settings: settings
    }
  end
end
