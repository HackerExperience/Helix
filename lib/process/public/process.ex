defmodule Helix.Process.Public.Process do

  alias Helix.Entity.Model.Entity
  alias Helix.Server.Model.Server
  alias Helix.Process.API.View.Process, as: ProcessView
  alias Helix.Process.Query.Process, as: ProcessQuery

  @spec index(Server.id, Entity.id) ::
    %{owned: [map], affecting: [map]}
  def index(server_id, entity_id) do
    processes_on_server = ProcessQuery.get_processes_on_server(server_id)

    processes_targeting_server =
      ProcessQuery.get_processes_targeting_server(server_id)

    processes_on_server = Enum.map(processes_on_server, fn process ->
      ProcessView.render(process.process_data, process, server_id, entity_id)
    end)
    processes_targeting_server = Enum.map(processes_targeting_server, fn
      process ->
        ProcessView.render(process.process_data, process, server_id, entity_id)
    end)

    %{
      owned: processes_on_server,
      affecting: processes_targeting_server
    }
  end
end
