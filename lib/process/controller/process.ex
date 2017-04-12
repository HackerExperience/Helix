defmodule Helix.Process.Controller.Process do

  alias HELL.PK
  alias Helix.Process.Repo
  alias Helix.Process.Model.Process
  alias Helix.Process.Model.Process.ProcessCreatedEvent
  alias Helix.Process.Model.Process.State

  @type find_param ::
    {:gateway, server :: PK.t}
    | {:target, server :: PK.t}
    | {:file, PK.t}
    | {:network, PK.t}
    | {:type, [String.t] | String.t}
    | {:state, [State.state] | State.state}

  @spec create(map) ::
    {:ok, Process.t, [event :: struct]}
    | {:error, Ecto.Changeset.t}
  def create(process) do
    changeset = Process.create_changeset(process)

    with {:ok, process} <- Repo.insert(changeset) do
      event = %ProcessCreatedEvent{
        process_id: process.process_id,
        gateway_id: process.gateway_id,
        target_id: process.target_server_id
      }

      {:ok, process, [event]}
    end
  end

  @spec fetch(PK.t) :: Process.t | nil
  def fetch(process_id),
    do: Repo.get(Process, process_id)

  @spec find([find_param], meta :: []) :: [Process.t]
  def find(params, _meta \\ []) do
    params
    |> Enum.reduce(Process, &reduce_find_params/2)
    |> Repo.all()
  end

  @spec delete(Process.t | PK.t) :: no_return
  def delete(process = %Process{}),
    do: delete(process.process_id)
  def delete(process_id) do
    process_id
    |> Process.Query.by_id()
    |> Repo.delete_all()

    :ok
  end

  @spec reduce_find_params(find_param, Ecto.Queryable.t) :: Ecto.Queryable.t
  defp reduce_find_params({:gateway, server_id}, query),
    do: Process.Query.by_gateway(query, server_id)
  defp reduce_find_params({:target, server_id}, query),
    do: Process.Query.by_target(query, server_id)
  defp reduce_find_params({:file, file_id}, query),
    do: Process.Query.by_file(query, file_id)
  defp reduce_find_params({:network, network_id}, query),
    do: Process.Query.by_network(query, network_id)
  defp reduce_find_params({:type, type_list}, query) when is_list(type_list),
    do: Process.Query.from_type_list(query, type_list)
  defp reduce_find_params({:type, process_type}, query),
    do: Process.Query.by_type(query, process_type)
  defp reduce_find_params({:state, state_list}, query)
  when is_list(state_list),
    do: Process.Query.from_state_list(query, state_list)
  defp reduce_find_params({:state, process_state}, query),
    do: Process.Query.by_state(query, process_state)
end
