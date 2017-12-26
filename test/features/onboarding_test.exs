defmodule Helix.Test.Features.Onboarding do

  use Helix.Test.Case.Integration

  alias Helix.Account.Action.Flow.Account, as: AccountFlow
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Story.Model.Step
  alias Helix.Story.Query.Story, as: StoryQuery

  alias HELL.TestHelper.Random

  describe "user onboarding" do
    test "initial player stuff was generated properly" do
      email = Random.email()
      username = Random.username()
      password = Random.password()

      # TODO: Use Phoenix endpoint for full integration test. Can't do it now
      # since public registrations are closed
      # Create the account
      assert {:ok, account} = AccountFlow.create(email, username, password)

      # Corresponding entity was created
      entity =
        account.account_id
        |> EntityQuery.get_entity_id()
        |> EntityQuery.fetch()

      assert entity.entity_type == :account

      # Player's initial server was created
      assert [server_id] = EntityQuery.get_servers(entity)
      server = ServerQuery.fetch(server_id)

      # Server has a valid motherboard attached to it
      assert server.motherboard_id

      # Initial server is always a desktop
      assert server.type == :desktop

      # Tutorial mission was created
      assert %{object: step} = StoryQuery.fetch_current_step(entity)
      assert step.name == Step.first_step_name()
    end
  end
end
