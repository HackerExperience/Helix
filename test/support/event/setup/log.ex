defmodule Helix.Test.Event.Setup.Log do

  alias Helix.Log.Model.Log

  alias Helix.Log.Event.Forge.Processed, as: LogForgeProcessedEvent
  alias Helix.Log.Event.Recover.Processed, as: LogRecoverProcessedEvent

  alias Helix.Log.Event.Log.Created, as: LogCreatedEvent
  alias Helix.Log.Event.Log.Destroyed, as: LogDestroyedEvent
  alias Helix.Log.Event.Log.Revised, as: LogRevisedEvent

  alias Helix.Test.Entity.Helper, as: EntityHelper
  alias Helix.Test.Log.Setup, as: LogSetup
  alias Helix.Test.Process.Setup, as: ProcessSetup

  def created,
    do: created(generate_fake_log())
  def created(log = %Log{}),
    do: LogCreatedEvent.new(log)

  def revised,
    do: revised(generate_fake_log())
  def revised(log = %Log{}),
    do: LogRevisedEvent.new(log)

  @doc """
  Opts:
  - process: Source process (optional).
  - process_type: `:log_forge_edit` or `:log_forge_created`. If not set, a
    random type will be selected
  """
  def forge_processed(opts) do
    process =
      if opts[:process] do
        opts[:process]
      else
        process_type = Keyword.get(opts, :process_type, :log_forge)
        ProcessSetup.fake_process!(type: process_type)
      end

    LogForgeProcessedEvent.new(process, process.data)
  end

  @doc """
  Opts:
  - process: Source process (optional).
  - process_type: `:log_recover_custom` or `:log_recover_global`. If not set, a
    random type will be selected.
  """
  def recover_processed(opts) do
    process =
      if opts[:process] do
        opts[:process]
      else
        process_type = Keyword.get(opts, :process_type, :log_recover)
        ProcessSetup.fake_process!(type: process_type)
      end

    LogRecoverProcessedEvent.new(process, process.data)
  end

  def destroyed,
    do: destroyed(generate_fake_log(), EntityHelper.id())
  def destroyed(log = %Log{}, entity_id),
    do: LogDestroyedEvent.new(log, entity_id)

  defp generate_fake_log do
    {log, _} = LogSetup.fake_log()
    log
  end
end
