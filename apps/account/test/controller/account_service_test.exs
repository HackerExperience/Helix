defmodule Helix.Account.Controller.AccountServiceTest do

  use ExUnit.Case, async: true

  alias HELF.Broker

  alias Helix.Account.Factory

  @moduletag :umbrella

  defp generate_params do
    :account
    |> Factory.build()
    |> Map.from_struct()
    |> Map.drop([:display_name, :__meta__])
  end

  describe "account creation" do
    test "succeeds with proper data" do
      params = generate_params()
      {_, {:ok, account}} = Broker.call("account.create", params)

      assert params.email === account.email
    end
  end
end