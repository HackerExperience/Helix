defmodule Helix.Story.Internal.Step do

  import HELL.Macros

  alias Helix.Entity.Model.Entity
  alias Helix.Story.Internal.Manager, as: ManagerInternal
  alias Helix.Story.Model.Step
  alias Helix.Story.Model.Story
  alias Helix.Story.Repo

  @type entry_step_repo_return ::
    {:ok, Story.Step.t}
    | {:error, Story.Step.changeset}

  @type step_info ::
    %{
      object: Step.t,
      entry: Story.Step.t
    }

  @spec fetch!(Step.t) ::
    Story.Step.t
    | no_return
  docp """
  Helper that fetches the underlying `Story.Step.t`
  """
  defp fetch!(%_{entity_id: entity_id, contact: contact_id}) do
    entity_id
    |> Story.Step.Query.by_entity()
    |> Story.Step.Query.by_contact(contact_id)
    |> Repo.one!()
  end

  @spec fetch_step(Entity.id, Step.contact) ::
    step_info
    | nil
  @doc """
  Returns the step of the player for the given contact.

  The result is formatted as a `step_info`, which contains both the Story.Step
  entry, and the Step struct, which we are calling `object`.

  It also formats the Step metadata, converting it back to Helix internal format
  """
  def fetch_step(entity_id, contact_id) do
    story_step =
      entity_id
      |> Story.Step.Query.by_entity()
      |> Story.Step.Query.by_contact(contact_id)
      |> Repo.one()

    if story_step do
      manager = ManagerInternal.fetch(entity_id)

      gather_data(story_step, manager)
    end
  end

  @spec get_steps(Entity.id) ::
    [step_info]
  @doc """
  Returns all steps that `entity_id` is currently at.

  Result is formatted as `step_info`.
  """
  def get_steps(entity_id) do
    manager = ManagerInternal.fetch(entity_id)

    entity_id
    |> Story.Step.Query.by_entity()
    |> Repo.all()
    |> Enum.map(fn entry ->
      gather_data(entry, manager)
    end)
  end

  @spec proceed(first_step :: Step.t) :: entry_step_repo_return
  @spec proceed(prev_step :: Step.t, next_step :: Step.t) ::
    {:ok, Story.Step.t}
    | {:error, :internal}
  @doc """
  Proceeds to the next step.

  If only one argument is passed, we assume the very first step is being created

  For all other cases, the previous step is removed and the next step is created
  """
  def proceed(first_step),
    do: create(first_step)
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

  @spec update_meta(Step.t) ::
    entry_step_repo_return
    | no_return
  @doc """
  Updates the Story.Step metadata.
  """
  def update_meta(step) do
    step
    |> fetch!()
    |> Story.Step.replace_meta(step.meta)
    |> update()
  end

  @spec unlock_reply(Step.t, Step.reply_id) ::
    entry_step_repo_return
    | no_return
  @doc """
  Marks a reply as unlock, allowing the player to use it as a valid reply.
  """
  def unlock_reply(step, reply_id) do
    step
    |> fetch!()
    |> Story.Step.unlock_reply(reply_id)
    |> update()
  end

  @spec lock_reply(Step.t, Step.reply_id) ::
    entry_step_repo_return
    | no_return
  @doc """
  Locks a reply, blocking the user from using it (again) as a valid reply
  """
  def lock_reply(step, reply_id) do
    step
    |> fetch!()
    |> Story.Step.lock_reply(reply_id)
    |> update()
  end

  @spec save_email(Step.t, Step.email_id) ::
    entry_step_repo_return
    | no_return
  @doc """
  Flags the given email as sent, so we know what the current step state is.

  It also inserts along all allowed replies to the email (i.e. the ones that
  are unlocked by default)
  """
  def save_email(step, email_id) do
    replies = Step.get_replies_of(step, email_id)

    step
    |> fetch!()
    |> Story.Step.append_email(email_id, replies)
    |> update()
  end

  @spec rollback_email(Step.t, Step.email_id) ::
    entry_step_repo_return
  @doc """
  Rollbacks the Story.Step emails to the specified checkpoint.
  """
  def rollback_email(step, checkpoint) do
    replies = Step.get_replies_of(step, checkpoint)

    step
    |> fetch!()
    |> Story.Step.rollback_email(checkpoint, replies)
    |> update()
  end

  @spec gather_data(Story.Step.t, Story.Manager.t) ::
    step_info
  docp """
  Helper that retrieves the `Step.t` based on the `story_step`
  """
  defp gather_data(story_step = %Story.Step{}, manager = %Story.Manager{}) do
    step =
      Step.fetch(
        story_step.step_name, story_step.entity_id, story_step.meta, manager
      )

    formatted_meta = Step.format_meta(step)

    %{
      object: %{step| meta: formatted_meta},
      entry: %{story_step| meta: formatted_meta}
    }
  end

  @spec create(Step.t) ::
    entry_step_repo_return
  defp create(step) do
    %{
      entity_id: step.entity_id,
      contact_id: step.contact,
      step_name: step.name,
      meta: step.meta
    }
    |> Story.Step.create_changeset()
    |> Repo.insert()
  end

  @spec update(Story.Step.changeset) ::
    entry_step_repo_return
  defp update(changeset),
    do: Repo.update(changeset)

  @spec remove(Step.t) ::
    :ok
  defp remove(step) do
    step
    |> fetch!()
    |> Repo.delete()

    :ok
  end
end
