defmodule Helix.Process.API.Process do

  alias Helix.Process.Query.Process, as: ProcessQuery
  alias Helix.Process.API.View.Process, as: ProcessView

  def index(server, entity) do
    processes_on_server = ProcessQuery.get_processes_on_server(server)

    processes_targeting_server =
      ProcessQuery.get_processes_targeting_server(server)

    processes_on_server = Enum.map(processes_on_server, fn process ->
      ProcessView.render(process.process_data, process, server, entity)
    end)
    processes_targeting_server = Enum.map(processes_targeting_server, fn
      process ->
        ProcessView.render(process.process_data, process, server, entity)
    end)

    %{
      owned: processes_on_server,
      affecting: processes_targeting_server
    }
  end
end
