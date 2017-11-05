defmodule Helix.Software.Event.Handler.File.TransferTest do

  use Helix.Test.Case.Integration

  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Software.Event.Handler.File.Transfer, as: FileTransferHandler
  alias Helix.Software.Query.File, as: FileQuery

  alias Helix.Test.Process.TOPHelper
  alias Helix.Test.Software.Setup.Flow, as: SoftwareFlowSetup

  describe "complete/1" do
    test "file is transferred (download)" do
      {process, _} = SoftwareFlowSetup.file_transfer(:download)

      {_, [event]} = TOPHelper.soft_complete(process)

      assert {:ok, new_file} = FileTransferHandler.complete(event)

      # Downloaded file has been saved on the database
      new_file = FileQuery.fetch(new_file.file_id)
      {:ok, server_id} = CacheQuery.from_storage_get_server(new_file.storage_id)

      # The new file has been saved on `gateway_id` (it was downloaded)
      assert server_id == process.gateway_id

      TOPHelper.top_stop(process.gateway_id)
    end

    test "file is transferred (upload)" do
      {process, _} = SoftwareFlowSetup.file_transfer(:upload)

      {_, [event]} = TOPHelper.soft_complete(process)

      assert {:ok, new_file} = FileTransferHandler.complete(event)

      # Uploaded file has been saved on the database
      new_file = FileQuery.fetch(new_file.file_id)
      {:ok, server_id} = CacheQuery.from_storage_get_server(new_file.storage_id)

      # The new file has been saved on `target_id` (it was uploaded)
      assert server_id == process.target_id

      TOPHelper.top_stop(process.gateway_id)
    end

    test "file is transferred (pftp_download)" do
      {process, _} = SoftwareFlowSetup.file_transfer(:pftp_download)

      {_, [event]} = TOPHelper.soft_complete(process)

      assert {:ok, new_file} = FileTransferHandler.complete(event)

      # Downloaded file has been saved on the database
      new_file = FileQuery.fetch(new_file.file_id)
      {:ok, server_id} = CacheQuery.from_storage_get_server(new_file.storage_id)

      # The new file has been saved on `gateway_id` (it was downloaded)
      assert server_id == process.gateway_id

      TOPHelper.top_stop(process.gateway_id)
    end

    @tag :pending
    test "failure cases"
  end
end
