defmodule Helix.Process.Public.Index do

  alias Helix.Entity.Model.Entity
  alias Helix.Server.Model.Server
  alias Helix.Process.Public.View.Process, as: ProcessView
  alias Helix.Process.Query.Process, as: ProcessQuery

  @type index ::
    %{
      owned: owned_process,
      targeting: targeting_process
    }

  @type owned_process :: [map]
  @type targeting_process :: [map]

  @spec index(Server.id, Entity.id) ::
    index
  @doc """
  Index for processes residing within the given server. The additional Entity
  parameter is required for context, since processes' details may be hidden or
  displayed for some entities.

  Does not require a renderer because this step is done by ProcessViewable, so
  the return of this function is already rendered and ready for the client.
  """
  def index(server_id, entity_id) do
    processes_on_server = ProcessQuery.get_processes_on_server(server_id)

    processes_targeting_server =
      ProcessQuery.get_processes_targeting_server(server_id)

    rendered_processes_on_server =
      Enum.map(processes_on_server, fn process ->
        ProcessView.render(process.process_data, process, server_id, entity_id)
      end)
    rendered_processes_targeting_server =
      Enum.map(processes_targeting_server, fn process ->
        ProcessView.render(process.process_data, process, server_id, entity_id)
      end)

    %{
      owned: rendered_processes_on_server,
      targeting: rendered_processes_targeting_server
    }
  end
end
