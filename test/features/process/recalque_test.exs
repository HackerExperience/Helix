# credo:disable-for-this-file Credo.Check.Readability.VariableNames
defmodule Helix.Test.Features.Process.Recalque do

  use Helix.Test.Case.Integration

  import Helix.Test.Macros
  import Helix.Test.Process.Macros

  alias Helix.Process.Query.Process, as: ProcessQuery
  alias Helix.Software.Public.File, as: FilePublic

  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Network.Setup, as: NetworkSetup
  alias Helix.Test.Process.Helper, as: ProcessHelper
  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Software.Helper, as: SoftwareHelper
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  @moduletag :feature

  @internet_id NetworkHelper.internet_id()

  describe "recalque" do
    # On this scenario, we have two servers. We'll start a few process on them
    # and see how they behave, specially inter-top resource utilization (DLK and
    # ULK).
    test "scenario one" do
      {serverA, _} = ServerSetup.server()
      {serverB, _} = ServerSetup.server()
      {serverC, _} = ServerSetup.server()

      resA = %{cpu: 300, ram: 200, dlk: 100, ulk: 10}
      resB = %{cpu: 250, ram: 150, dlk: 50, ulk: 30}
      resC = %{cpu: 200, ram: 100, dlk: 30, ulk: 10}

      ServerHelper.update_server_specs(serverA, resA)
      ServerHelper.update_server_specs(serverB, resB)
      ServerHelper.update_server_specs(serverC, resC)

      storageA = SoftwareHelper.get_storage(serverA)
      storageC = SoftwareHelper.get_storage(serverC)

      {tunnelAB, _} =
        NetworkSetup.tunnel(
          gateway_id: serverA.server_id, destination_id: serverB.server_id
        )

      {tunnelCB, _} =
        NetworkSetup.tunnel(
          gateway_id: serverC.server_id, destination_id: serverB.server_id
        )

      {dl_file, _} = SoftwareSetup.file(server_id: serverB.server_id)

      # Create a download process
      assert {:ok, %{process_id: downloadA_id}} =
        FilePublic.download(serverA, serverB, tunnelAB, storageA, dl_file)

      # Give some time for allocation
      # :timer.sleep(50)

      # Let's fetch the Process, as this is the moment when the actual
      # allocation is loaded.
      downloadA = ProcessQuery.fetch(downloadA_id)
      orig_downloadA = downloadA

      # The download uses 30 units of DLK of serverA
      assert_resource downloadA.l_allocated.dlk[@internet_id], resB.ulk

      # And it uses 30 units of ULK of serverB
      assert_resource downloadA.r_allocated.ulk[@internet_id], resB.ulk

      # All other resources are unused (except RAM, due to static allocations)
      assert downloadA.l_allocated.ulk[@internet_id] == 0
      assert downloadA.l_allocated.cpu == 0
      assert downloadA.l_allocated.ram > 0

      assert downloadA.r_allocated.dlk == %{}
      assert downloadA.r_allocated.cpu == 0
      assert downloadA.r_allocated.ram == 0

      # All good! Let's make this story more exciting.

      ### Chapter 2 ###

      # Now, serverA will start a local-only process, which should not affect
      # the download's local or remote resources.
      {cracker, _} = SoftwareSetup.cracker(server_id: serverA.server_id)

      ipB = ServerHelper.get_ip(serverB)

      # Start the Bruteforce attack
      assert {:ok, %{process_id: bruteforce_id}} =
        FilePublic.bruteforce(cracker, serverA, serverB, @internet_id, ipB, [])

      # Give some time for allocation
      # :timer.sleep(50)

      bruteforce = ProcessQuery.fetch(bruteforce_id)

      # All CPU of serverA was assigned to the Bruteforce process
      assert bruteforce.l_allocated.cpu == resA.cpu

      # Does not use other resources (except RAM due to static allocations)
      assert bruteforce.l_allocated.dlk[@internet_id] == 0
      assert bruteforce.l_allocated.ulk[@internet_id] == 0
      assert bruteforce.l_allocated.ram > 0

      assert bruteforce.r_allocated.ulk == %{}
      assert bruteforce.r_allocated.dlk == %{}
      assert bruteforce.r_allocated.cpu == 0
      assert bruteforce.r_allocated.ram == 0

      downloadA2 = ProcessQuery.fetch(downloadA_id)

      # After recalque, the Download process remains unchanged
      # (The time_left may have changed a little bit, but that's because some
      # time has passed since it was created :)
      # assert downloadA2 == downloadA
      assert_map downloadA2, downloadA, skip: [:time_left, :completion_date]

      ### Chapter 3 ###

      # Now things get real. A new server, `C` will also start a download on `B`
      # This will reduce B's ULK availability, and the previously started
      # download process should be recalculated.
      # Notice this is our first chain reaction: When C starts its download, TOP
      # will be recalculate on C and B. Then, it should recalculate A.

      assert {:ok, %{process_id: downloadC_id}} =
        FilePublic.download(serverC, serverB, tunnelCB, storageC, dl_file)

      # :timer.sleep(50)

      downloadC = ProcessQuery.fetch(downloadC_id)
      downloadA = ProcessQuery.fetch(downloadA_id)

      # DownloadC DLK allocation is exactly half of B's ULK
      assert_resource downloadC.l_allocated.dlk[@internet_id], resB.ulk / 2
      assert_resource downloadC.r_allocated.ulk[@internet_id], resB.ulk / 2

      # Now, downloadA is using half of B's ULK as well
      assert_resource downloadA.l_allocated.dlk[@internet_id], resB.ulk / 2
      assert_resource downloadA.r_allocated.ulk[@internet_id], resB.ulk / 2

      # The process duration has roughly doubled, since it's using half of the
      # resources from before
      assert_in_delta downloadA.time_left, orig_downloadA.time_left * 2, 1

      # downloadA has processed a little bit during this time
      refute downloadA.processed == orig_downloadA.processed
      refute \
        downloadA.last_checkpoint_time == orig_downloadA.last_checkpoint_time

      # This `processed` information is actually saved on the DB
      raw_downloadA = ProcessHelper.raw_get(downloadA_id)
      assert raw_downloadA.processed["dlk"]["::"] > 0
      assert raw_downloadA.processed["ram"] > 0
    end
  end
end
