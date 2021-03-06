defmodule Helix.Process.Internal.ProcessTest do

  use Helix.Test.Case.Integration

  alias Helix.Process.Internal.Process, as: ProcessInternal

  alias Helix.Test.Process.Helper, as: ProcessHelper
  alias Helix.Test.Process.Setup, as: ProcessSetup
  alias Helix.Test.Process.Helper, as: ProcessHelper
  alias Helix.Test.Process.TOPHelper

  describe "create/1" do
    test "inserts the process on the database" do
      {_, %{params: params}} = ProcessSetup.fake_process()

      assert {:ok, process} = ProcessInternal.create(params)

      # Required / input data is correct
      assert process.gateway_id == params.gateway_id
      assert process.source_entity_id == params.source_entity_id
      assert process.target_id == params.target_id
      assert process.network_id == params.network_id
      assert process.src_connection_id == params.src_connection_id
      assert process.src_file_id == params.src_file_id
      assert process.tgt_connection_id == params.tgt_connection_id
      assert process.tgt_file_id == params.tgt_file_id
      assert process.data == params.data
      assert process.type == params.type
      assert process.objective == params.objective
      assert process.static == params.static
      assert process.l_dynamic == params.l_dynamic
      assert process.r_dynamic == params.r_dynamic

      # Generated / default data is correct
      assert process.creation_time
      refute process.last_checkpoint_time
      assert process.priority == 3

      # Now we'll test the actual format the data was saved on the DB.
      # We'll have some trouble with maps, which convert all atoms to strings..
      entry = ProcessHelper.raw_get(process)

      assert entry

      # All IDs are in the expected Helix format
      assert entry.process_id == process.process_id
      assert entry.gateway_id == process.gateway_id
      assert entry.target_id == process.target_id
      assert entry.source_entity_id == process.source_entity_id
      assert entry.network_id == process.network_id
      assert entry.src_file_id == process.src_file_id
      assert entry.src_connection_id == process.src_connection_id
      assert entry.tgt_file_id == process.tgt_file_id
      assert entry.tgt_connection_id == process.tgt_connection_id

      # Atoms, or a list of them, are converted automatically back to atoms
      assert entry.l_dynamic == process.l_dynamic
      assert entry.r_dynamic == process.r_dynamic
      assert entry.type == process.type

      # Because of NaiveStruct type, we have the Struct loaded
      assert entry.data.__struct__ == params.data.__struct__

      # However its values still need formatting
      # Resource maps, too, need reformatting.

      # The conversion of the above values into our internal format (atoms,
      # maps, structs) is done with `format/1`. All calls to `fetch/1` (among
      # other `get_*` functions) have their result automatically `format`-ted.
      # Notice this wasn't the case here because we've executed a "raw_query",
      # which did not send our process to `format/1`.

      # Anyway, testing `format/1` is not our goal. See `Process.format/1`.
      TOPHelper.top_stop()
    end
  end

  describe "fetch/1" do
    test "returns the process, formatted" do
      {process, _} = ProcessSetup.process()

      entry = ProcessInternal.fetch(process.process_id)

      assert entry

      # The returned data was formatted, it's exactly the same as defined before
      assert entry.data == process.data

      # Added some virtual data
      assert entry.state

      # Resource data is identical
      assert entry.objective == process.objective
      assert entry.processed == process.processed
      assert entry.static == process.static

      # Populated derived data
      assert entry.l_allocated
      assert entry.r_allocated
      assert entry.state
      assert entry.time_left
      assert entry.completion_date

      TOPHelper.top_stop()
    end

    test "returns empty when process does not exist" do
      refute ProcessInternal.fetch(ProcessHelper.id())
    end
  end

  describe "delete/1" do
    test "removes entry" do
      {process, _} = ProcessSetup.process()

      # It is on the DB
      assert ProcessInternal.fetch(process.process_id)

      # Request to remove the process
      ProcessInternal.delete(process)

      # No longer on DB
      refute ProcessInternal.fetch(process.process_id)

      TOPHelper.top_stop()
    end
  end
end
