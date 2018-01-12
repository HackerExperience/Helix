# credo:disable-for-this-file Credo.Check.Refactor.CyclomaticComplexity
defmodule Helix.Process.Executable do
  @moduledoc """
  Process.Executable is a simple and declarative approach describing what should
  happen when a given process is executed.

  What `file` should this process modify? Is it related to a connection? Should
  a connection be created? What is the process data? And so on.

  Too tired to write proper API usage documentation. Please refer to existing
  Processes to learn how to use `Process.Executable`.
  """

  import HELL.Macros

  alias Helix.Event
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Network.Action.Tunnel, as: TunnelAction
  alias Helix.Network.Model.Connection
  alias Helix.Network.Model.Network
  alias Helix.Network.Query.Network, as: NetworkQuery
  alias Helix.Server.Model.Server
  alias Helix.Software.Model.File
  alias Helix.Process.Action.Process, as: ProcessAction
  alias Helix.Process.Model.Process

  @doc """
  Figures out the Process module based on the Executable's path.
  """
  def get_process(caller) do
    caller.module
    |> Module.split()
    |> Enum.drop(-1)
    |> Module.concat()
  end

  docp """
  Collection of "handlers", i.e. methods that will make sense of the result and
  create the desired Process.creation_params
  """
  defp handlers(process) do
    quote do
      @spec get_process_data(params) ::
        %{data: unquote(process).t}
      docp """
      Retrieves the `process_data`, according to how it was defined at the
      Process' `new/1`. Subset of the full process params.
      """
      defp get_process_data(params) do
        data = call_process(:new, params)
        %{data: data}
      end

      @spec get_ownership(Server.t, Server.t, params, meta) ::
        %{
          gateway_id: Server.id,
          target_id: Server.id,
          source_entity_id: Entity.id
        }
      docp """
      Infers ownership information about the process, which is a subset of the
      full process params.
      """
      defp get_ownership(gateway, target, params, meta) do
        entity = EntityQuery.fetch_by_server(gateway.server_id)
        %{
          gateway_id: gateway.server_id,
          target_id: target.server_id,
          source_entity_id: entity.entity_id
        }
      end

      @spec get_process_type(term) ::
        %{type: Process.type}
      docp """
      Returns the `process_type` parameter, a subset of the full process params.
      """
      defp get_process_type(%{type: process_type}),
        do: %{type: process_type}
      defp get_process_type(_) do
        process_type = call_process(:get_process_type)
        %{type: process_type}
      end

      @spec get_network_id(term) ::
        %{network_id: Network.id | nil}
      docp """
      Returns the `network_id` parameter, a subset of the full process params.
      """
      defp get_network_id(%{network_id: network_id}),
        do: %{network_id: network_id}
      defp get_network_id(_),
        do: %{network_id: nil}

      @spec merge_params(
        map,
        Connection.t | nil | %{connection_id: nil},
        Connection.t | nil | %{connection_id: nil})
      ::
        Process.creation_params
      defp merge_params(params, nil, target_connection),
        do: merge_params(params, %{connection_id: nil}, target_connection)
      defp merge_params(params, connection, nil),
        do: merge_params(params, connection, %{connection_id: nil})
      defp merge_params(
        params,
        %{connection_id: src_connection_id},
        %{connection_id: tgt_connection_id})
      do
        params
        |> Map.merge(%{connection_id: src_connection_id})
        |> Map.merge(%{target_connection_id: tgt_connection_id})
      end
    end
  end

  docp """
  Utils for Process.Executable inner workings.
  """
  defp utils(process) do
    quote do

      @spec call_process(atom) ::
        term
      docp """
      Helper used to call functions on the Process' module directly.
      """
      defp call_process(function),
        do: apply(unquote(process), function, [])
      defp call_process(function, params),
        do: apply(unquote(process), function, [params])

      @spec close_connection_on_fail(nil, Event.relay) :: :noop
      @spec close_connection_on_fail(Connection.t, Event.relay) :: term
      docp """
      Helper called when `flow` of `execute/4` fails, and a connection may have
      to be closed as a result.
      """
      defp close_connection_on_fail(nil, _),
        do: :noop
      defp close_connection_on_fail(connection, relay) do
        connection
        |> TunnelAction.close_connection()
        |> Event.emit(from: relay)
      end

      @spec setup_connection(
        Server.t,
        Server.t,
        term,
        meta,
        {:create, Connection.type},
        origin :: Connection.t | nil)
      ::
        {:ok, Connection.t, [event :: term]}
      defp setup_connection(gateway, target, _, meta, {:create, type}, _) do
        create_connection(
          meta.network_id,
          gateway.server_id,
          target.server_id,
          meta.bounce,
          type
        )
      end

      @spec setup_connection(
        Server.t,
        Server.t,
        term,
        meta,
        :same_origin,
        Connection.t)
      ::
        {:ok, Connection.t, []}
      defp setup_connection(_, _, _, _, :same_origin, origin = %Connection{}),
        do: {:ok, origin, []}

      @spec setup_connection(
        Server.t,
        Server.t,
        term,
        meta,
        nil | :ok | :noop,
        Connection.t | nil)
      ::
        {:ok, nil, []}
      defp setup_connection(_, _, _, _, _, _),
        do: {:ok, nil, []}

      @spec create_connection(Network.id, Server.id, Server.id, term, term) ::
        {:ok, Connection.t, [event :: term]}
      docp """
      Creates a new connection.
      """
      defp create_connection(
        network_id = %Network.ID{},
        gateway_id,
        target_id,
        bounce,
        type)
      do
        TunnelAction.connect(
          NetworkQuery.fetch(network_id),
          gateway_id,
          target_id,
          bounce,
          type
        )
      end
    end
  end

  @doc """
  Top-level macro for defining the `Process.Executable` behavior.
  """
  defmacro executable(do: block) do
    process = __CALLER__.module

    quote location: :keep do

      defmodule Executable do

        import HELF.Flow
        import HELL.Macros
        import Helix.Process.Executable

        @type executable_error ::
          {:error, :resources}
          | {:error, :internal}

        # Generates the entry point for Process.Executable
        execute(gateway, target, params, meta)

        unquote(block)

        # Generates the handlers
        unquote(handlers(process))

        # Generates the utils
        unquote(utils(process))

        # Defaults: in case these functions were not defined, we assume the
        # process is not interested on this (optional) data.

        defp get_connection(_, _, _, _),
          do: nil

        defp get_file(_, _, _, _),
          do: %{file_id: nil}

        defp get_target_connection(_, _, _, _),
          do: nil

        defp get_target_file(_, _, _, _),
          do: %{target_file_id: nil}
      end
    end
  end

  @doc """
  Entry point for process executions. Implements the complete Executable flow.
  """
  defmacro execute(gateway, target, params, meta) do
    args = [gateway, target, params, meta]

    quote location: :keep do

      @spec execute(Server.t, Server.t, params, meta, Event.relay) ::
        {:ok, Process.t}
        | executable_error
      @doc """
      Executes the process.
      """
      def execute(unquote_splicing(args), relay) do
        process_data = get_process_data(unquote(params))
        resources = get_resources(unquote_splicing(args))
        file = get_file(unquote_splicing(args))
        target_file = get_target_file(unquote_splicing(args))
        ownership = get_ownership(unquote_splicing(args))
        process_type = get_process_type(unquote(meta))
        network_id = get_network_id(unquote(meta))

        partial =
          %{}
          |> Map.merge(process_data)
          |> Map.merge(resources)
          |> Map.merge(file)
          |> Map.merge(target_file)
          |> Map.merge(ownership)
          |> Map.merge(process_type)
          |> Map.merge(network_id)

        connection_info = get_connection(unquote_splicing(args))
        target_connection_info = get_target_connection(unquote_splicing(args))

        flowing do
          with \
            {:ok, connection, events} <-
              setup_connection(unquote_splicing(args), connection_info, nil),

            # Compensated transactions for the potentially new connection
            on_success(fn -> Event.emit(events, from: relay) end),
            on_fail(fn -> close_connection_on_fail(connection, relay) end),

            {:ok, target_connection, events} <-
              setup_connection(
                unquote_splicing(args), target_connection_info, connection
              ),

            # Compensated transactions for the potentially new connection
            on_success(fn -> Event.emit(events, from: relay) end),
            on_fail(
              fn -> close_connection_on_fail(target_connection, relay) end
            ),

            # Merge connection and target_connection data to the process params
            params = merge_params(partial, connection, target_connection),

            # Finally create the process
            {:ok, process, events} <- ProcessAction.create(params),

            on_success(fn -> Event.emit(events, from: relay) end)
          do
            {:ok, process}
          else
            {:error, :resources} ->
              {:error, :resources}

            {:error, %Ecto.Changeset{}} ->
              {:error, :internal}
          end
        end
      end

    end
  end

  @doc """
  Returns the raw result of the Executable's `connection` section. It will be
  later interpreted by `setup_connection`, which will make sense whether a new
  connection should be created, and what the `connection_id` should be set to.
  """
  defmacro connection(gateway, target, params, meta, do: block) do
    args = [gateway, target, params, meta]

    quote do

      @spec get_connection(term, term, term, term) ::
        {:create, Connection.type}
        | nil
      @doc false
      defp get_connection(unquote_splicing(args)) do
        unquote(block)
      end

    end
  end

  @doc """
  Returns the raw result of the Executable's `target_connection` section. It
  will be later interpreted by `setup_connection`, which will make sense whether
  a new connection should be created, and what the `target_connection_id` should
  be set to.

  If `:same_origin` is returned, the process will target the same connection
  that originated it.
  """
  defmacro target_connection(gateway, target, params, meta, do: block) do
    args = [gateway, target, params, meta]

    quote do

      @spec get_target_connection(term, term, term, term) ::
        {:create, Connection.type}
        | :same_origin
        | nil
      @doc false
      defp get_target_connection(unquote_splicing(args)) do
        unquote(block)
      end

    end
  end

  @doc """
  Returns information about the resource usage of that process, including:

  - what is the process objective
  - which resources can be allocated dynamically
  - what are the statically allocated resources
  """
  defmacro resources(gateway, target, params, meta, do: block) do
    args = [gateway, target, params, meta]
    process = get_process(__CALLER__)

    quote do

      @spec get_resources(term, term, term, term) ::
        unquote(process).resources
      @doc false
      defp get_resources(unquote_splicing(args)) do
        params = unquote(block)

        call_process(:resources, params)
      end

    end
  end

  @doc """
  Returns the process' `file_id`, as defined on the `file` section of the
  Process.Executable.
  """
  defmacro file(gateway, target, params, meta, do: block) do
    args = [gateway, target, params, meta]

    quote do

      @spec get_file(term, term, term, term) ::
        %{file_id: File.t | nil}
      @doc false
      defp get_file(unquote_splicing(args)) do
        file_id = unquote(block)

        %{file_id: file_id}
      end

    end
  end

  @doc """
  Returns the process' `target_file_id`, as defined on the `target_file` section
  of the Process.Executable.
  """
  defmacro target_file(gateway, target, params, meta, do: block) do
    args = [gateway, target, params, meta]

    quote do

      @spec get_target_file(term, term, term, term) ::
        %{target_file_id: File.t | nil}
      @doc false
      defp get_target_file(unquote_splicing(args)) do
        file_id = unquote(block)

        %{target_file_id: file_id}
      end

    end
  end
end
