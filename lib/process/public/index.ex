defmodule Helix.Process.Public.Index do

  alias Helix.Entity.Model.Entity
  alias Helix.Server.Model.Server
  alias Helix.Process.Public.View.Process, as: ProcessView
  alias Helix.Process.Query.Process, as: ProcessQuery

  @type index ::
    %{
      local: [local_process],
      remote: [remote_process]
    }

  @type local_process :: map
  @type remote_process :: map

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
    processes = ProcessQuery.get_processes_on_server(server_id)

    local_processes = Enum.filter(processes, &(&1.gateway_id == server_id))
    remote_processes = processes -- local_processes

    rendered_local_processes =
      Enum.map(local_processes, fn process ->
        ProcessView.render(process.data, process, server_id, entity_id)
      end)
    rendered_remote_processes =
      Enum.map(remote_processes, fn process ->
        ProcessView.render(process.data, process, server_id, entity_id)
      end)

    %{
      local: rendered_local_processes,
      remote: rendered_remote_processes
    }
  end
end
