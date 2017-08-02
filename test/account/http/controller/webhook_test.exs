defmodule Helix.Account.HTTP.Controller.WebhookTest do

  use Helix.Test.ConnCase
  use Helix.Test.IntegrationCase

  alias Comeonin.Bcrypt
  alias Helix.Cache.Helper, as: CacheHelper
  alias Helix.Account.Query.Account, as: AccountQuery

  @token "Bearer " <> Application.get_env(:helix, :migration_token)

  describe "import" do
    test "succeeds with valid data", context do
      input_data = %{
        "username" => "iLikeTrains",
        "password" => Bcrypt.hashpwsalt("this is my very secret password"),
        "email" => "i@like.trains"
      }

      context.conn
      |> put_req_header("authorization", @token)
      |> post(
        api_v1_webhook_path(context.conn, :import_from_migration),
        input_data)
      |> json_response(200)

      account = AccountQuery.fetch_by_username(input_data["username"])

      assert account
      assert account.confirmed
      assert input_data["password"] == account.password
      assert input_data["username"] == account.display_name
      assert String.downcase(input_data["username"]) == account.username
      assert String.downcase(input_data["email"]) == account.email

      # The account setup event was emited, so we better wait
      :timer.sleep(500)
      CacheHelper.sync_test()
    end

    test "fails if request token is invalid", context do
      input_data = %{
        "username" => "iLikeTrains",
        "password" => Bcrypt.hashpwsalt("this is my very secret password"),
        "email" => "i@like.trains"
      }

      response =
        context.conn
        |> put_req_header("authorization", "Bearer invalidToken")
        |> post(
          api_v1_webhook_path(context.conn, :import_from_migration),
          input_data)
        |> json_response(403)

      assert response["message"] =~ "token"
    end
  end
end
