defmodule Helix.Log.Factor.LogTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Factor.Macros

  alias Helix.Log.Factor.Log, as: LogFactor
  alias Helix.Log.Internal.Log, as: LogInternal

  alias Helix.Test.Entity.Helper, as: EntityHelper
  alias Helix.Test.Log.Helper, as: LogHelper
  alias Helix.Test.Log.Setup, as: LogSetup

  describe "LogFactor.Revisions" do
    test "fact: :from_entity" do
      log = LogSetup.log!()
      entity_id = EntityHelper.id()
      info = LogHelper.log_info()
      version = 50

      params = %{log: log, entity_id: entity_id}

      {fact, relay} = get_fact(LogFactor.Revisions, :from_entity, params)

      assert fact == 0
      assert length(relay.revisions) == 1

      # Add a revision from `entity_id`
      LogInternal.revise(log, entity_id, info, version)

      {fact, relay} = get_fact(LogFactor.Revisions, :from_entity, params)

      assert fact == 1
      assert length(relay.revisions) == 2

      # Add a revision from some other entity
      LogInternal.revise(log, EntityHelper.id(), info, version)

      {fact, relay} = get_fact(LogFactor.Revisions, :from_entity, params)

      assert fact == 1
      assert length(relay.revisions) == 3
    end

    test "fact: :total" do
      log = LogSetup.log!()
      info = LogHelper.log_info()
      version = 50

      params = %{log: log}

      {fact, relay} = get_fact(LogFactor.Revisions, :total, params)

      assert fact == 1
      assert length(relay.revisions) == 1

      # Add a revision from `entity_id`
      LogInternal.revise(log, EntityHelper.id(), info, version)

      {fact, relay} = get_fact(LogFactor.Revisions, :total, params)

      assert fact == 2
      assert length(relay.revisions) == 2
    end
  end
end
