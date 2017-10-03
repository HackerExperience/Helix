defmodule Helix.Story.Action.Story do

  alias Helix.Story.Internal.Email, as: EmailInternal
  alias Helix.Story.Internal.Step, as: StepInternal
  alias Helix.Story.Model.Step
  alias Helix.Story.Model.StoryEmail
  alias Helix.Story.Model.StoryStep
  alias Helix.Story.Repo

  alias Helix.Story.Event.Email.Sent, as: EmailSentEvent
  alias Helix.Story.Event.Reply.Sent, as: ReplySentEvent
  alias Helix.Story.Event.Step.Proceeded, as: StepProceededEvent

  @spec proceed_step(first_step :: Step.t(struct)) ::
    {:ok, StoryStep.t}
    | {:error, :internal}
  @spec proceed_step(prev_step :: Step.t(struct), next_step :: Step.t(struct)) ::
    {:ok, StoryStep.t}
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

  @spec update_step_meta(Step.t(struct)) ::
    StepInternal.entry_step_repo_return
    | no_return
  @doc """
  Updates the StoryStep metadata.
  """
  def update_step_meta(step),
    do: StepInternal.update_meta(step)

  @spec unlock_reply(Step.t(struct), Step.reply_id) ::
    StepInternal.entry_step_repo_return
    | no_return
  @doc """
  Marks a reply as unlock, allowing the player to use it as a valid reply.
  """
  def unlock_reply(step, reply_id),
    do: StepInternal.unlock_reply(step, reply_id)

  @spec lock_reply(Step.t(struct), Step.reply_id) ::
    StepInternal.entry_step_repo_return
    | no_return
  @doc """
  Locks a reply, blocking the user from using it (again) as a valid reply
  """
  def lock_reply(step, reply_id),
    do: StepInternal.lock_reply(step, reply_id)

  @spec notify_step(Step.t(struct), Step.t(struct)) ::
    [StepProceededEvent.t]
  @doc """
  Generates the StepProceededEvent, used to notify the client about the progress
  made.
  """
  def notify_step(prev_step, next_step),
    do: [step_proceeded_event(prev_step, next_step)]

  @spec send_email(Step.t(struct), Step.email_id, Step.email_meta) ::
    {:ok, [EmailSentEvent.t]}
    | {:error, :internal}
  @doc """
  Sends an email from the contact to the player.

  When the email is sent (saved on StoryEmail), it is also saved on StoryStep,
  maintaining the Step state.

  During the StoryStep save, it overwrites the `allowed_replies` from the
  previous email (if any) to the default allowed replies of the email_id.
  """
  def send_email(step, email_id, meta) do
    Repo.transaction(fn ->
      with \
        {:ok, _, email} <- EmailInternal.send_email(step, email_id, meta),
        {:ok, _} <- StepInternal.save_email(step, email_id)
      do
        [email_sent_event(step, email)]
      else
        _ ->
          Repo.rollback(:internal)
      end
    end)
  end

  @spec send_reply(Step.t(struct), StoryStep.t, Step.reply_id) ::
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
          StoryStep.can_send_reply?(story_step, reply_id)
          || {:reply, :not_found},
        {:ok, _, email} <- EmailInternal.send_reply(step, reply_id),
        {:ok, _} <- StepInternal.lock_reply(step, reply_id)
      do
        reply_to = StoryStep.get_current_email(story_step)
        [reply_received_event(step, reply_to, email)]
      else
        # When elixir-lang issue #6426 gets fixed, rewrite to use :badreply
        error ->
          Repo.rollback(error)
      end
    end)
  end

  @spec email_sent_event(Step.t(struct), StoryEmail.email) ::
    EmailSentEvent.t
  defp email_sent_event(step, email) do
    %EmailSentEvent{
      entity_id: step.entity_id,
      step: step.name,
      email_id: email.id,
      meta: email.meta,
      timestamp: email.timestamp
    }
  end

  @spec reply_received_event(Step.t(struct), Step.reply_id, StoryEmail.email) ::
    ReplySentEvent.t
  defp reply_received_event(step, reply_to, email) do
    %ReplySentEvent{
      entity_id: step.entity_id,
      step: step.name,
      reply_to: reply_to,
      reply_id: email.id,
      timestamp: email.timestamp
    }
  end

  @spec step_proceeded_event(Step.t(struct), Step.t(struct)) ::
    StepProceededEvent.t
  defp step_proceeded_event(prev_step, next_step) do
    %StepProceededEvent{
      entity_id: next_step.entity_id,
      previous_step: prev_step.name,
      next_step: next_step.name
    }
  end
end
