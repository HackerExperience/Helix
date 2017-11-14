defmodule Helix.Story.Internal.Step do

  alias Helix.Entity.Model.Entity
  alias Helix.Story.Model.Step
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

  @spec fetch_current_step(Entity.id) ::
    %{
      object: Step.t(struct),
      entry: StoryStep.t
    }
    | nil
  @doc """
  Returns the current step of the player, both the StoryStep entry, and the
  Step struct, which we are calling `object`.

  It also formats the Step metadata, converting it back to Helix internal format
  """
  def fetch_current_step(entity_id) do
    story_step =
      entity_id
      |> StoryStep.Query.by_entity()
      |> Repo.one()

    if story_step do
      step =
        Step.fetch(story_step.step_name, story_step.entity_id, story_step.meta)

      formatted_meta = Step.format_meta(step)

      %{
        object: %{step| meta: formatted_meta},
        entry: %{story_step| meta: formatted_meta}
      }
    end
  end

  @spec proceed(first_step :: Step.t(struct)) ::
    entry_step_repo_return
  @spec proceed(prev_step :: Step.t(struct), next_step :: Step.t(struct)) ::
    {:ok, StoryStep.t}
    | {:error, :internal}
  @doc """
  Proceeds to the next step.

  If only one argument is passed, we assume the very first step is being created

  For all other cases, the previous step is removed and the next step is created
  """
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
        _ ->
          Repo.rollback(:internal)
      end
    end)
  end

  @spec update_meta(Step.t(struct)) ::
    entry_step_repo_return
    | no_return
  @doc """
  Updates the StoryStep metadata.
  """
  def update_meta(step) do
    step
    |> fetch!()
    |> StoryStep.replace_meta(step.meta)
    |> update()
  end

  @spec unlock_reply(Step.t(struct), Step.reply_id) ::
    entry_step_repo_return
    | no_return
  @doc """
  Marks a reply as unlock, allowing the player to use it as a valid reply.
  """
  def unlock_reply(step, reply_id) do
    step
    |> fetch!()
    |> StoryStep.unlock_reply(reply_id)
    |> update()
  end

  @spec lock_reply(Step.t(struct), Step.reply_id) ::
    entry_step_repo_return
    | no_return
  @doc """
  Locks a reply, blocking the user from using it (again) as a valid reply
  """
  def lock_reply(step, reply_id) do
    step
    |> fetch!()
    |> StoryStep.lock_reply(reply_id)
    |> update()
  end

  @spec save_email(Step.t(struct), Step.email_id) ::
    entry_step_repo_return
    | no_return
  @doc """
  Flags the given email as sent, so we know what the current step state is.

  It also inserts along all allowed replies to the email (i.e. the ones that
  are unlocked by default)
  """
  def save_email(step, email_id) do
    replies = Step.get_replies(step, email_id)

    step
    |> fetch!()
    |> StoryStep.append_email(email_id, replies)
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
