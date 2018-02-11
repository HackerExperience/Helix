defmodule Helix.Story.Quests.Tutorial.DownloadCrackerTest do

  use Helix.Test.Case.Integration

  alias Helix.Story.Model.Steppable

  alias Helix.Test.Story.Setup, as: StorySetup

  describe "setup/1" do
    test "creates the context/environment; idempotent" do
      {step, _} = StorySetup.step(
        name: :tutorial@download_cracker, meta: %{}, ready: true
      )

      assert {meta, _, _events} = Steppable.setup(step)

      assert meta.server_id
      assert meta.cracker_id
      assert meta.ip

      # Ensure idempotency
      step = %{step| meta: meta}
      assert {meta2, _, _events} = Steppable.setup(step)
      assert meta2 == meta
    end
  end

  describe "callbacks" do
    # Tested on `StoryHandlerTest`
    # test "on_file_deleted" do
    # end
  end
end
