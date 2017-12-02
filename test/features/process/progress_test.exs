defmodule Helix.Test.Features.Process.Progress do

  use Helix.Test.Case.Integration

  alias Helix.Process.Action.TOP, as: TOPAction
  alias Helix.Process.Query.Process, as: ProcessQuery
  alias Helix.Software.Public.File, as: FilePublic

  alias Helix.Test.Network.Setup, as: NetworkSetup
  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Software.Helper, as: SoftwareHelper
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  @moduletag :feature

  @relay nil

  describe "percentage" do

    # Scenario: `server` will download a file from `target`. We'll pause and
    # query the process again, after some time, to make sure it calculates the
    # process estimated progress percentage.
    test "percentage is updated as process progresses" do
      {server, _} = ServerSetup.server()
      {target, _} = ServerSetup.server()

      res_server = %{dlk: 100, ulk: 100}
      res_target = %{dlk: 100, ulk: 100}

      ServerHelper.update_server_specs(server, res_server)
      ServerHelper.update_server_specs(target, res_target)

      storage = SoftwareHelper.get_storage(server)

      {tunnel, _} =
        NetworkSetup.tunnel(
          gateway_id: server.server_id, destination_id: target.server_id
        )

      # File has size 100, and will be downloaded at rate 100/s. So it takes 1s
      {dl_file, _} = SoftwareSetup.file(server_id: target.server_id, size: 100)

      assert {:ok, %{process_id: download_id}} =
        FilePublic.download(server, target, tunnel, storage, dl_file, @relay)

      # We've just started the downloaded, so it ran ~0%
      download0 = ProcessQuery.fetch(download_id)
      assert_in_delta download0.percentage, 0, 0.08
      assert_in_delta download0.time_left, 1.0, 0.08

      # Sleep 100ms, which is about 10%
      :timer.sleep(100)

      # Yep, we are somewhere near 10%
      download1 = ProcessQuery.fetch(download_id)
      assert_in_delta download1.percentage, 0.1, 0.08
      assert_in_delta download1.time_left, 0.9, 0.08

      # Sleep another 100ms (+10%)
      :timer.sleep(100)

      # Percentage is at 20%
      download2 = ProcessQuery.fetch(download_id)
      assert_in_delta download2.percentage, 0.2, 0.08

      # Now we'll tragically make increase the download time.
      # The time_left will increase, but the percentage shouldn't change
      ServerHelper.update_server_specs(server, %{dlk: 1})

      # Run recalque so the new server specs are applied to the process
      TOPAction.recalque(server.server_id)

      download3 = ProcessQuery.fetch(download_id)

      # Time left increase 100 fold
      assert_in_delta download3.time_left, download2.time_left * 100, 1

      # Percentage barely changed
      assert_in_delta download3.percentage, download2.percentage, 0.01
    end
  end
end
