defmodule Helix.Story.Query.StoryTest do

  use Helix.Test.Case.Integration

  alias Helix.Entity.Model.Entity
  alias Helix.Story.Query.Story, as: StoryQuery

  alias Helix.Test.Entity.Helper, as: EntityHelper
  alias Helix.Test.Story.Helper, as: StoryHelper
  alias Helix.Test.Story.Setup, as: StorySetup

  describe "fetch_step/1" do
    test "returns correct data" do
      {entry, %{entity_id: entity_id, step: step}} = StorySetup.story_step()

      result = StoryQuery.fetch_step(entity_id, step.contact)

      assert result
      assert result.object == step
      assert result.entry == entry
    end

    test "returns nil if nothing was found" do
      refute StoryQuery.fetch_step(
        EntityHelper.id(), StoryHelper.contact_id()
      )
    end
  end

  describe "get_emails/1" do
    test "returns all contact emails" do
      {generated, %{entity_id: entity_id}} =
        StorySetup.lots_of_emails_and_contacts()

      emails = StoryQuery.get_emails(entity_id)

      assert generated == emails
    end
  end
end
