defmodule Helix.Story.Model.MacroTest do

  use Helix.Test.Case.Integration

  import ExUnit.CaptureLog

  alias Helix.Software.Internal.File, as: FileInternal
  alias Helix.Story.Model.Steppable

  alias Helix.Test.Event.Setup, as: EventSetup
  alias Helix.Test.Story.Setup, as: StorySetup

  describe "on_reply" do
    test "it pattern-matches correctly" do
      {_, %{step: step}} =
        StorySetup.story_step(name: :fake_steps@test_msg, meta: %{})

      # reply_to_e1 tests the `do` block
      r1_event = EventSetup.Story.reply_sent(step, "reply_to_e1", "e1")

      assert capture_log(fn ->
        Steppable.handle_event(step, r1_event, %{})
      end) =~ "replied_to_e1"

      # reply_to_e2 tests the `send` block
      r2_event = EventSetup.Story.reply_sent(step, "reply_to_e2", "e2")

      {{action, email_id, meta, _}, _, []} =
        Steppable.handle_event(step, r2_event, %{})

      assert action == :send_email
      assert email_id == "e3"
      assert meta == %{}

      # reply_to_e3 tests the `complete` block
      r3_event = EventSetup.Story.reply_sent(step, "reply_to_e3", "e3")

      {action, _, []} = Steppable.handle_event(step, r3_event, %{})
      assert action == :complete

      # Below events test the case where no pattern is matched
      unmatched_reply_event =
        EventSetup.Story.reply_sent(step, "reply_to_e3", "e1")

      assert {:noop, _, []} =
        Steppable.handle_event(step, unmatched_reply_event, %{})

      invalid_reply_event =
        EventSetup.Story.reply_sent(step, "not_exists", "e3")

      assert {:noop, _, []} =
        Steppable.handle_event(step, invalid_reply_event, %{})
    end
  end

  describe "setup_once" do
    test "handles hit and misses" do
      # NOTE: The step used here is simply for dummy data; that's why this test
      # will probably be repeated on the same step's tests

      {step, _} = StorySetup.step(
        name: :tutorial@download_cracker,
        meta: %{},
        ready: true
      )

      # Generate for the first time (100% misses)
      assert {meta, _, _events} = Steppable.setup(step)

      assert meta.cracker_id
      assert meta.server_id
      assert meta.ip

      # Try again, now redoing everything (for idempotency, should be 100% hits)
      step = %{step| meta: meta}
      assert {meta2, _, _events} = Steppable.setup(step)
      assert meta2 == meta

      # Now we'll nuke the `cracker_id`.
      meta.cracker_id
      |> FileInternal.fetch()
      |> FileInternal.delete()

      # As a result, a new `cracker_id` should be generated, but everything else
      # should be the same
      assert {meta3, _, _events} = Steppable.setup(step)

      # New cracker was generated
      refute meta3.cracker_id == meta.cracker_id

      # But the other stuff is the same
      assert meta3.server_id == meta.server_id
      assert meta3.ip == meta.ip
    end
  end
end
