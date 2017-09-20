defmodule Helix.Story.Internal.Step do

  alias Helix.Entity.Model.Entity
  alias Helix.Story.Model.Step
  alias Helix.Story.Model.Steppable
  alias Helix.Story.Model.StoryStep
  alias Helix.Story.Repo

  @type entry_step_repo_return ::
    {:ok, StoryStep.t}
    | {:error, StoryStep.changeset}

  @spec fetch!(Step.t(struct)) ::
    StoryStep.t
    | no_return
  defp fetch!(%{entity_id: entity_id, name: step_name}) do
    entity_id
    |> StoryStep.Query.by_entity()
    |> StoryStep.Query.by_step(step_name)
    |> Repo.one!()
  end

  @spec get_current_step(Entity.id) ::
    StoryStep.t
    | nil
  def get_current_step(entity_id) do
    story_step =
      entity_id
      |> StoryStep.Query.by_entity()
      |> Repo.one()

    if story_step do
      formatted_meta =
        Step.fetch(story_step.step_name, story_step.entity_id, story_step.meta)
        |> Steppable.format_meta()

      %{story_step|meta: formatted_meta}
    end
  end

  @spec proceed(first_step :: Step.t(struct)) ::
    entry_step_repo_return
  @spec proceed(prev_step :: Step.t(struct), next_step :: Step.t(struct)) ::
    {:ok, StoryStep.t}
    | {:error, term}
  def proceed(next_step),
    do: create(next_step)
  def proceed(prev_step, next_step) do
    Repo.transaction(fn ->
      with \
        :ok <- remove(prev_step),
        {:ok, entry} <- create(next_step)
      do
        entry
      else
        error ->
          Repo.rollback(error)
      end
    end)
  end
  @spec update_meta(Step.t(struct)) ::
    entry_step_repo_return
    | no_return
  def update_meta(step) do
    step
    |> fetch!()
    |> StoryStep.replace_meta(step.meta)
    |> update()
  end

  @spec unlock_reply(Step.t(struct), Step.reply_id) ::
    entry_step_repo_return
    | no_return
  def unlock_reply(step, reply_id) do
    step
    |> fetch!()
    |> StoryStep.unlock_reply(reply_id)
    |> update()
  end

  @spec save_email(Step.t(struct), Step.email_id) ::
    entry_step_repo_return
    | no_return
  def save_email(step, email_id) do
    step
    |> fetch!()
    |> StoryStep.append_email(email_id)
    |> update()
  end

  @spec create(Step.t(struct)) ::
    entry_step_repo_return
  defp create(step) do
    %{
      entity_id: step.entity_id,
      step_name: step.name,
      meta: step.meta
    }
    |> StoryStep.create_changeset()
    |> Repo.insert()
  end

  @spec update(StoryStep.changeset) ::
    entry_step_repo_return
  defp update(changeset),
    do: Repo.update(changeset)

  @spec remove(Step.t(struct)) ::
    :ok
  defp remove(step) do
    step
    |> fetch!()
    |> Repo.delete()

    :ok
  end
end
