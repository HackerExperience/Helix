defmodule Helix.Story.Action.Story do

  alias Helix.Story.Internal.Email, as: EmailInternal
  alias Helix.Story.Internal.Step, as: StepInternal
  alias Helix.Story.Model.Step
  alias Helix.Story.Model.StoryEmail
  alias Helix.Story.Model.StoryStep
  alias Helix.Story.Repo

  alias Helix.Story.Event.Step.Proceeded, as: StepProceededEvent
  alias Helix.Story.Event.Email.Sent, as: EmailSentEvent
  alias Helix.Story.Event.Reply.Sent, as: ReplySentEvent

  @spec proceed_step(first_step :: Step.t(struct)) ::
    {:ok, StoryStep.t}
    | {:error, :internal}
  @spec proceed_step(prev_step :: Step.t(struct), next_step :: Step.t(struct)) ::
    {:ok, StoryStep.t}
    | {:error, :internal}
  def proceed_step(first_step),
    do: StepInternal.proceed(first_step)
  def proceed_step(prev_step, next_step),
    do: StepInternal.proceed(prev_step, next_step)

  @spec update_step_meta(Step.t(struct)) ::
    StepInternal.entry_step_repo_return
    | no_return
  def update_step_meta(step),
    do: StepInternal.update_meta(step)

  @spec update_step_emails(Step.t(struct), Step.email_id) ::
    StepInternal.entry_step_repo_return
    | no_return
  def update_step_emails(step, email_sent),
    do: StepInternal.save_email(step, email_sent)

  @spec unlock_reply(Step.t(struct), Step.reply_id) ::
    StepInternal.entry_step_repo_return
    | no_return
  def unlock_reply(step, reply_id),
    do: StepInternal.unlock_reply(step, reply_id)

  @spec notify_step(Step.t(struct), Step.t(struct)) ::
    [StepProceededEvent.t]
  def notify_step(prev_step, next_step),
    do: [step_proceeded_event(prev_step, next_step)]

  @spec send_email(Step.t(struct), Step.email_id, Step.email_meta) ::
    {:ok, [EmailSentEvent.t]}
    | {:error, :internal}
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
  def send_reply(step, story_step, reply_id) do
    Repo.transaction(fn ->
      with \
        true <-
          StoryStep.can_send_reply?(story_step, reply_id)
          || {:reply, :notfound},
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
