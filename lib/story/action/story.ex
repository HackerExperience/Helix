defmodule Helix.Story.Action.Story do

  alias Helix.Story.Internal.Email, as: EmailInternal
  alias Helix.Story.Internal.Step, as: StepInternal
  alias Helix.Story.Model.Step

  @spec proceed_step(prev_step :: Step.t(term), next_step :: Step.t(term)) ::
    :ok
    | :error
  def proceed_step(prev_step, next_step) do
    case StepInternal.proceed(prev_step, next_step) do
      {:ok, _} ->
        :ok
      {:error, _} ->
        :error
    end
  end

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

  @spec notify_step(Step.t(struct)) ::
    [term]
  def notify_step(step),
    do: step_proceeded_event(step)

  @spec step_proceeded_event(Step.t(struct)) ::
    [term]
  defp step_proceeded_event(_step) do
    %{}
  end

  @spec send_email(Step.t(struct), Step.email_id, Step.email_meta) ::
    {:ok, term}
    | :error
  def send_email(step, email_id, meta) do
    case EmailInternal.send_email(step, email_id, meta) do
      {:ok, email} ->
        {:ok, [email_sent_event(step, email)]}
      _ ->
        :error
    end
  end

  @spec send_reply(Step.t(struct), Step.reply_id, Step.email_id) ::
    {:ok, term}
    | :error
  def send_reply(step, reply_id, reply_to) do
    case EmailInternal.send_reply(step, reply_id) do
      {:ok, email} ->
        {:ok, [reply_received_event(step, reply_to, email)]}
      _ ->
        :error
    end
  end

  @spec email_sent_event(Step.t(struct), StoryEmail.email) ::
    term
  defp email_sent_event(step, email) do
    %{
      entity_id: step.entity_id,
      step: step.name,
      email: email.id,
      meta: email.meta,
      timestamp: email.timestamp
    }
  end

  @spec reply_received_event(Step.t(struct), Step.reply_id, StoryEmail.email) ::
    term
  defp reply_received_event(step, reply_to, email) do
    %{
      entity_id: step.entity_id,
      step: step.name,
      reply_to: reply_to,
      reply: email.id,
      meta: email.meta,
      timestamp: email.timestamp
    }
  end
end
