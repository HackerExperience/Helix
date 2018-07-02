defmodule Helix.Story.Action.Story do

  alias Helix.Story.Internal.Email, as: EmailInternal
  alias Helix.Story.Internal.Step, as: StepInternal
  alias Helix.Story.Model.Step
  alias Helix.Story.Model.Story
  alias Helix.Story.Repo

  alias Helix.Story.Event.Email.Sent, as: EmailSentEvent
  alias Helix.Story.Event.Reply.Sent, as: ReplySentEvent
  alias Helix.Story.Event.Step.Proceeded, as: StepProceededEvent
  alias Helix.Story.Event.Step.Restarted, as: StepRestartedEvent

  @spec proceed_step(first_step :: Step.t) ::
    {:ok, Story.Step.t}
    | {:error, :internal}
  @spec proceed_step(prev_step :: Step.t, next_step :: Step.t) ::
    {:ok, Story.Step.t}
    | {:error, :internal}
  @doc """
  Proceeds to the next step.

  If only one argument is passed, we assume the very first step is being created

  For all other cases, the previous step is removed and the next step is created
  """
  def proceed_step(first_step),
    do: StepInternal.proceed(first_step)
  def proceed_step(prev_step, next_step),
    do: StepInternal.proceed(prev_step, next_step)

  @spec update_step_meta(Step.t) ::
    StepInternal.entry_step_repo_return
    | no_return
  @doc """
  Updates the Story.Step metadata.
  """
  def update_step_meta(step),
    do: StepInternal.update_meta(step)

  @spec unlock_reply(Step.t, Step.reply_id) ::
    StepInternal.entry_step_repo_return
    | no_return
  @doc """
  Marks a reply as unlock, allowing the player to use it as a valid reply.
  """
  def unlock_reply(step, reply_id),
    do: StepInternal.unlock_reply(step, reply_id)

  @spec lock_reply(Step.t, Step.reply_id) ::
    StepInternal.entry_step_repo_return
    | no_return
  @doc """
  Locks a reply, blocking the user from using it (again) as a valid reply
  """
  def lock_reply(step, reply_id),
    do: StepInternal.lock_reply(step, reply_id)

  @spec publish_step(Step.t, Step.t) ::
    [StepProceededEvent.t]
  @doc """
  Generates the StepProceededEvent, used to publish to the Client about the
  progress made.
  """
  def publish_step(prev_step, next_step),
    do: [StepProceededEvent.new(prev_step, next_step)]

  @spec publish_restart(Step.t, atom, Step.email_id, Step.email_meta) ::
    [StepRestartedEvent.t]
  @doc """
  Generates the StepRestartedEvent, used to publish to the Client that the step
  has been restarted
  """
  def publish_restart(step, reason, checkpoint, meta),
    do: [StepRestartedEvent.new(step, reason, checkpoint, meta)]

  @spec send_email(Step.t, Step.email_id, Step.email_meta) ::
    {:ok, [EmailSentEvent.t]}
    | {:error, {:email, :not_found}}
    | {:error, :internal}
  @doc """
  Sends an email from the contact to the player.

  When the email is sent (saved on Story.Email), it is also saved on Story.Step,
  maintaining the Step state.

  May fail with `{:email, :not_found}` if for some reason it's attempting to
  send an email that does not exist. This is most likely a programmer's error.

  During the Story.Step save, it overwrites the `allowed_replies` from the
  previous email (if any) to the default allowed replies of the email_id.
  """
  def send_email(step, email_id, meta) do
    Repo.transaction(fn ->
      with \
        true <- Step.email_exists?(step, email_id) || {:email, :not_found},
        {:ok, _, email} <- EmailInternal.send_email(step, email_id, meta),
        {:ok, _} <- StepInternal.save_email(step, email_id)
      do
        [EmailSentEvent.new(step, email)]
      else
        error ->
          Repo.rollback(error)
      end
    end)
  end

  @spec send_reply(Step.t, Story.Step.t, Step.reply_id) ::
    {:ok, [ReplySentEvent.t]}
    | {:error, {:reply, :not_found}}
    | {:error, :internal}
  @doc """
  Sends a reply from the player to the contact

  May fail with `{:reply, :not_found}` if the given reply is invalid within that
  context, i.e. either the reply id does not exist or is not listed under the
  allowed_replies entry.

  After sent, the reply id is removed from the list of allowed_replies in order
  to avoid the player from repeatedly sending the same reply.
  """
  def send_reply(step, story_step, reply_id) do
    Repo.transaction(fn ->
      with \
        true <-
          Story.Step.can_send_reply?(story_step, reply_id)
          || {:reply, :not_found},
        {:ok, _, email} <- EmailInternal.send_reply(step, reply_id),
        {:ok, _} <- StepInternal.lock_reply(step, reply_id),
        {:ok, _} <- StepInternal.save_email(step, reply_id)
      do
        reply_to = Story.Step.get_current_email(story_step)
        [ReplySentEvent.new(step, email, reply_to)]
      else
        # When elixir-lang issue #6426 gets fixed, rewrite to use :badreply
        error ->
          Repo.rollback(error)
      end
    end)
  end

  @spec rollback_emails(Step.t, Step.email_id, Step.email_meta) ::
    {:ok, Story.Step.t, Story.Email.t}
    | {:error, :internal}
  @doc """
  Rollbacks the messages on `step` to the specified `checkpoint`.

  Note that within the Story domain, messages are saved on two places:
  - within Story.Step, used for internal step stuff (handling replies, etc)
  - within Story.Email, used for listing messages per contact (with metadata)

  As such, we need to update (rollback) to the checkpoint on both places.

  The `allowed_replies` list, specified at `Story.Step.t`, will also be updated
  with the default (unlocked) replies listed on `checkpoint` declaration.
  """
  def rollback_emails(step, checkpoint, meta) do
    result =
      Repo.transaction fn ->
        with \
          {:ok, story_step} <- StepInternal.rollback_email(step, checkpoint),
          {:ok, email} <- EmailInternal.rollback_email(step, checkpoint, meta)
        do
          {story_step, email}
        else
          _ ->
            Repo.rollback(:internal)
        end
      end

    with {:ok, {story_step, story_email}} <- result do
      {:ok, story_step, story_email}
    end
  end
end
