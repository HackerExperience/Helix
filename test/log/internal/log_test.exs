defmodule Helix.Log.Internal.LogTest do

  use Helix.Test.Case.Integration

  alias Helix.Log.Internal.Log, as: LogInternal

  alias Helix.Test.Entity.Helper, as: EntityHelper
  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Software.Helper, as: SoftwareHelper
  alias Helix.Test.Log.Helper, as: LogHelper
  alias Helix.Test.Log.Setup, as: LogSetup

  describe "create/4" do
    test "creates natural log (without forge_version)" do
      server_id = ServerHelper.id()
      entity_id = EntityHelper.id()
      log_info = {log_type, log_data} = LogHelper.log_info()

      assert {:ok, log} = LogInternal.create(server_id, entity_id, log_info)

      # Current revision maps to the correct data
      assert log.revision_id == 1
      assert log.revision.type == log_type
      assert log.revision.data == Map.from_struct(log_data)
      assert log.revision.entity_id == entity_id
      refute log.revision.forge_version

      # And some other not-so-important verifications
      assert log.revision.creation_time == log.creation_time
    end

    test "creates artificial log (with forge_version)" do
      server_id = ServerHelper.id()
      entity_id = EntityHelper.id()
      log_info = {log_type, log_data} = LogHelper.log_info()
      forger_version = SoftwareHelper.random_version()

      assert {:ok, log} =
        LogInternal.create(server_id, entity_id, log_info, forger_version)

      # Current revision maps to the correct data
      assert log.revision_id == 1
      assert log.revision.type == log_type
      assert log.revision.data == Map.from_struct(log_data)
      assert log.revision.entity_id == entity_id
      assert log.revision.forge_version == forger_version

      # And some other not-so-important verifications
      assert log.revision.creation_time == log.creation_time
    end
  end

  describe "revise/4" do
    test "adds a revision to the log entry" do
      log = LogSetup.log!()

      new_entity_id_1 = EntityHelper.id()
      new_info_1 = {new_type_1, new_data_1} = LogHelper.log_info()
      new_version_1 = 50

      # Add a revision (second overall)
      assert {:ok, new_log_1} =
        LogInternal.revise(log, new_entity_id_1, new_info_1, new_version_1)

      # The new log `revision_id` points to another revision
      assert new_log_1.revision_id == 2

      # The returned log's `revision` has changed
      assert new_log_1.revision.entity_id == new_entity_id_1
      assert new_log_1.revision.type == new_type_1
      assert new_log_1.revision.data == Map.from_struct(new_data_1)
      assert new_log_1.revision.forge_version == new_version_1

      # But stuff that shouldn't change hasn't changed
      assert new_log_1.creation_time == log.creation_time

      new_entity_id_2 = EntityHelper.id()
      new_info_2 = {new_type_2, new_data_2} = LogHelper.log_info()
      new_version_2 = 100

      # Add yet another revision (third overall)
      assert {:ok, new_log_2} =
        LogInternal.revise(
          new_log_1, new_entity_id_2, new_info_2, new_version_2
        )

      # The new log `revision_id` points to another revision
      assert new_log_2.revision_id == 3

      # The returned log's `revision` has changed
      assert new_log_2.revision.entity_id == new_entity_id_2
      assert new_log_2.revision.type == new_type_2
      assert new_log_2.revision.data == Map.from_struct(new_data_2)
      assert new_log_2.revision.forge_version == new_version_2

      # But stuff that shouldn't change hasn't changed
      assert new_log_2.creation_time == log.creation_time
    end
  end

  describe "recover/1" do
    test "returns own log when last revision of natural log" do
      log = LogSetup.log!()

      # When recovering the last revision of a natural log, we must return the
      # log itself.
      assert {:original, same_log} = LogInternal.recover(log)

      # We can't assert `same_log == log` because of some Ecto internals...
      assert same_log.log_id == log.log_id
      assert same_log.revision_id == log.revision_id

      # Log was not deleted
      assert LogInternal.fetch(log.log_id)
    end

    test "destroys log when last revision of artificial log" do
      log = LogSetup.log!(forge_version: 50)

      assert :destroyed == LogInternal.recover(log)

      # Log was deleted
      refute LogInternal.fetch(log.log_id)
    end

    test "recovers natural log with multiple revisions" do
      log = LogSetup.log!(revisions: 3)

      [_rev3, rev2, rev1] = LogHelper.get_all_revisions(log.log_id)

      # Recover the first (originally 3 revisions)
      assert {:recovered, new_log1} = LogInternal.recover(log)

      # Popped last revision from stack
      assert new_log1.revision_id == 2
      assert new_log1.revision.type == rev2.type
      assert new_log1.revision.data == rev2.data
      assert new_log1.revision.entity_id == rev2.entity_id
      assert new_log1.revision.forge_version == rev2.forge_version

      # Without changing stuff that shouldn't be changed
      assert new_log1.creation_time == log.creation_time

      # Recover the second (originally 3 revisions)
      assert {:recovered, new_log2} = LogInternal.recover(new_log1)

      # Popped last revision from stack
      assert new_log2.revision_id == 1
      assert new_log2.revision.type == rev1.type
      assert new_log2.revision.data == rev1.data
      assert new_log2.revision.entity_id == rev1.entity_id
      assert new_log2.revision.forge_version == rev1.forge_version

      # Without changing stuff that shouldn't be changed
      assert new_log2.creation_time == log.creation_time

      # Can't recover any further, as we are currently at the original revision
      assert {:original, new_log2} == LogInternal.recover(new_log2)
    end

    test "recovers artificial log with multiple revisions" do
      log = LogSetup.log!(revisions: 2, forge_version: 20)

      [_rev2, rev1] = LogHelper.get_all_revisions(log.log_id)

      assert {:recovered, new_log1} = LogInternal.recover(log)

      # Popped last revision from stack
      assert new_log1.revision_id == 1
      assert new_log1.revision.type == rev1.type
      assert new_log1.revision.data == rev1.data
      assert new_log1.revision.entity_id == rev1.entity_id
      assert new_log1.revision.forge_version == rev1.forge_version

      # Without changing stuff that shouldn't be changed
      assert new_log1.creation_time == log.creation_time

      # And when attempting to recover once again, the artificial log is deleted
      assert :destroyed == LogInternal.recover(new_log1)
    end
  end
end
