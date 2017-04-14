defmodule Helix.Process.Service.Event.TOP do

  alias Helix.Process.Controller.Process, as: Controller
  alias Helix.Process.Controller.TableOfProcesses
  alias Helix.Process.Model.Process.ProcessCreatedEvent
  alias Helix.Process.Service.Local.TOP.Manager

  def process_created(event = %ProcessCreatedEvent{}) do
    process = Controller.fetch(event.process_id)

    {:ok, pid} = Manager.prepare_top(process.gateway_id)

    TableOfProcesses.recalculate(pid)
  end
end
