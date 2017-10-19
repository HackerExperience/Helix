defmodule Helix.Test.Event.Setup.Story do

  alias Helix.Story.Event.Email.Sent, as: StoryEmailSentEvent
  alias Helix.Story.Event.Reply.Sent, as: StoryReplySentEvent
  alias Helix.Story.Event.Step.Proceeded, as: StoryStepProceededEvent

  alias HELL.TestHelper.Random
  alias Helix.Test.Story.Setup, as: StorySetup

  def email_sent do
    {step, _} = StorySetup.step()
    email_sent(step, Random.string())
  end

  def email_sent(step, email_id, email_meta \\ %{}) do
    {email, _} = StorySetup.fake_email(id: email_id, meta: email_meta)

    StoryEmailSentEvent.new(step, email)
  end

  def reply_sent do
    {step, _} = StorySetup.step()
    reply_sent(step, Random.string(), Random.string())
  end

  def reply_sent(step, reply_id, reply_to) do
    {reply, _} = StorySetup.fake_email(id: reply_id)

    StoryReplySentEvent.new(step, reply, reply_to)
  end

  def step_proceeded do
    {prev_step, next_step, _} = StorySetup.step_sequence()
    step_proceeded(prev_step, next_step)
  end

  def step_proceeded(prev_step, next_step) do
    StoryStepProceededEvent.new(prev_step, next_step)
  end
end
