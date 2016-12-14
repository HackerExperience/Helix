defmodule HELM.Account.Controller.AccountServiceTest do

  use ExUnit.Case, async: true

  alias HELF.Broker

  @moduletag :umbrella

  setup do
    {:ok, params: account_create_params()}
  end

  defp account_create_params do
    email = Burette.Internet.email()
    password = Burette.Internet.password()
    %{email: email, password_confirmation: password, password: password}
  end

  @tag :pending
  test "create account", %{params: params} do
    {:ok, account} = Broker.call("account:create", params)
    assert params.email === account.email
  end
end