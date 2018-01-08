defmodule Helix.Software.Event.Handler.Virus do

  alias Helix.Event

  alias Helix.Software.Event.File.Install.Processed,
    as: FileInstallProcessedEvent

  def virus_installed(event = %FileInstallProcessedEvent{backend: :virus}) do
    IO.puts "viurs installd #{inspect event}"
  end
  def virus_installed(%FileInstallProcessedEvent{backend: _}),
    do: :noop
end
