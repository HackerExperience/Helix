defmodule Helix.Test.Event.Setup.Log do

  alias Helix.Log.Event.Log.Created, as: LogCreatedEvent
  alias Helix.Log.Event.Log.Deleted, as: LogDeletedEvent
  alias Helix.Log.Event.Log.Modified, as: LogModifiedEvent
  alias Helix.Log.Model.Log

  alias Helix.Test.Log.Setup, as: LogSetup

  def created,
    do: created(generate_fake_log())

  def created(log = %Log{}),
    do: LogCreatedEvent.new(log)

  def modified,
    do: modified(generate_fake_log())

  def modified(log = %Log{}),
    do: LogModifiedEvent.new(log)

  def deleted,
    do: deleted(generate_fake_log())

  def deleted(log = %Log{}),
    do: LogDeletedEvent.new(log)

  defp generate_fake_log do
    {log, _} = LogSetup.fake_log()
    log
  end
end
