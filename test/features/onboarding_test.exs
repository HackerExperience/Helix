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

      # Create the account
      # TODO: Use Phoenix endpoint for full integration test. Can't do it now
      # since public registrations are closed
      assert {:ok, account} = AccountFlow.create(email, username, password)

      # Corresponding entity was created
      entity =
        account.account_id
        |> EntityQuery.get_entity_id()
        |> EntityQuery.fetch()

      assert entity.entity_type == :account

      # Player's initial servers were created
      assert [story_server_id, server_id] = EntityQuery.get_servers(entity)

      server = ServerQuery.fetch(server_id)
      story_server = ServerQuery.fetch(story_server_id)

      # Both servers have a valid motherboard attached to it
      assert server.motherboard_id
      assert story_server.motherboard_id

      # One of the servers is for the story...
      assert server.type == :desktop
      assert story_server.type == :desktop_story

      # Tutorial mission was created
      assert [%{object: step}] = StoryQuery.get_steps(entity.entity_id)
      assert step.name == Step.first_step_name()
    end
  end
end
