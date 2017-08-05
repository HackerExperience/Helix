defmodule Helix.Process.Internal.ProcessTest do

  use Helix.Test.IntegrationCase

  alias Helix.Process.Internal.Process, as: ProcessInternal
  alias Helix.Process.Model.Process
  alias Helix.Process.Repo

  alias Helix.Process.Factory

  describe "fetching" do
    test "succeeds by id" do
      process = Factory.insert(:process)
      assert %Process{} = ProcessInternal.fetch(process.process_id)
    end

    test "fails when process doesn't exists" do
      refute ProcessInternal.fetch(Process.ID.generate())
    end
  end

  describe "delete/1" do
    @tag :pending
    test "is idempotent" do
      process = Factory.insert(:process)

      assert Repo.get(Process, process.process_id)
      ProcessInternal.delete(process)
      ProcessInternal.delete(process)
      refute Repo.get(Process, process.process_id)
    end
  end
end
