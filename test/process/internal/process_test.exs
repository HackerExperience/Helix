defmodule Helix.Process.Internal.ProcessTest do

  use Helix.Test.Case.Integration

  alias Helix.Process.Internal.Process, as: ProcessInternal
  alias Helix.Process.Model.Process

  alias Helix.Test.Process.Setup, as: ProcessSetup

  describe "fetching" do
    test "succeeds by id" do
      {process, _} = ProcessSetup.process()
      entry = ProcessInternal.fetch(process.process_id)

      # Returned the correct entry
      assert entry.process_id == process.process_id

      # Loaded/formatted the entry from DB (virtual data)
      assert entry.minimum
      assert Map.has_key?(entry, :estimated_time)
    end

    test "fails when process doesn't exists" do
      refute ProcessInternal.fetch(Process.ID.generate())
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
    end
  end
end
