defmodule Helix.Test.Story.Helper do

  alias Helix.Story.Internal.Step, as: StepInternal
  alias Helix.Story.Model.Story
  alias Helix.Story.Repo, as: StoryRepo

  def remove_existing_step(entity_id) do
    entity_id
    |> StepInternal.get_steps()
    |> Enum.each(&(StoryRepo.delete(&1.entry)))
  end

  def get_steps_from_entity(entity_id) do
    entity_id
    |> Story.Step.Query.by_entity()
    |> StoryRepo.all()
  end

  def get_allowed_reply(entry) do
    entry
    |> Story.Step.get_allowed_replies()
    |> Enum.random()
  end

  @doc """
  Generates random contact id
  """
  def contact_id do
    # Guaranteed to be random
    :friend
  end

  @doc """
  Generates random reply id
  """
  def reply_id do
    # Guaranteed to be random
    "reply_id"
  end
end
