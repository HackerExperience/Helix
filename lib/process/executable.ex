# credo:disable-for-this-file Credo.Check.Refactor.CyclomaticComplexity
defmodule Helix.Process.Executable do

  alias Helix.Event
  alias Helix.Network.Action.Tunnel, as: TunnelAction
  alias Helix.Network.Query.Network, as: NetworkQuery
  alias Helix.Process.Action.Process, as: ProcessAction
  alias Helix.Network.Model.Connection
  alias Helix.Network.Model.Network

  defmacro __using__(_args) do
    quote do

      import HELF.Flow
      import HELL.Macros
      import Helix.Process.Executable

      @before_compile unquote(__MODULE__)

      execute(gateway, target, params, meta)
    end
  end

  defmacro __before_compile__(_env) do
    quote do

      docp """
      Retrieves the `process_data`, according to how it was defined at the
      Process' `new/1`. Subset of the full process params.
      """
      defp get_process_data(params) do
        data = call_process(:new, params)
        %{process_data: data}
      end

      docp """
      Infers ownership information about the process, which is a subset of the
      full process params.
      """
      defp get_ownership(gateway, target, params, meta) do
        %{
          gateway_id: gateway.server_id,
          target_server_id: target.server_id
        }
      end

      docp """
      Returns the `process_type` parameter, a subset of the full process params.
      """
      defp get_process_type(%{process_type: process_type}),
        do: %{process_type: process_type |> to_string()}
      defp get_process_type(_) do
        process_type = call_process(:get_process_type)
        %{process_type: process_type}
      end

      docp """
      Returns the `network_id` parameter, a subset of the full process params.
      """
      defp get_network_id(%{network_id: network_id}),
        do: %{network_id: network_id}
      defp get_network_id(_),
        do: %{network_id: nil}

      docp """
      Helper used to call functions on the Process' module directly.
      """
      defp call_process(function),
        do: apply(@process, function, [])
      defp call_process(function, params),
        do: apply(@process, function, [params])

      docp """
      Merges the partial process params with other data (connection_id).
      """
      defp create_process_params(partial, %{connection_id: connection_id}),
        do: Map.put(partial, :connection_id, connection_id)
      defp create_process_params(partial, nil),
        do: Map.put(partial, :connection_id, nil)

      docp """
      Helper called when `flow` of `execute/4` fails, and a connection may have
      to be closed as a result.
      """
      defp close_connection_on_fail(nil),
        do: :noop
      defp close_connection_on_fail(connection),
        do: TunnelAction.close_connection(connection)

      docp """
      Interprets the result of `get_connection/4` and, if required, creates a
      new connection.
      """
      defp setup_connection(gateway, target, _, meta, {:create, conn_type}) do
        create_connection(
          meta.network_id,
          gateway.server_id,
          target.server_id,
          meta.bounce,
          conn_type
        )
      end

      defp setup_connection(_, _, _, _, _),
        do: {:ok, nil, []}

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

  defmacro executable(do: block) do
    quote do

      defmodule Executable do

        use Helix.Process.Executable

        unquote(block)
      end

    end
  end

  defmacro execute(gateway, target, params, meta) do
    args = [gateway, target, params, meta]

    quote do

      def execute(unquote_splicing(args)) do
        process_data = get_process_data(unquote(params))
        objective = get_objective(unquote_splicing(args))
        file = get_file(unquote_splicing(args))
        ownership = get_ownership(unquote_splicing(args))
        process_type = get_process_type(unquote(meta))
        network_id = get_network_id(unquote(meta))

        partial =
          %{}
          |> Map.merge(process_data)
          |> Map.merge(objective)
          |> Map.merge(file)
          |> Map.merge(ownership)
          |> Map.merge(process_type)
          |> Map.merge(network_id)

        connection_info = get_connection(unquote_splicing(args))

        flowing do
          with \
            {:ok, connection, events} <-
              setup_connection(unquote_splicing(args), connection_info),

            on_success(fn -> Event.emit(events) end),
            on_fail(fn -> close_connection_on_fail(connection) end),

            params = create_process_params(partial, connection),

            {:ok, process, events} <- ProcessAction.create(params),

            on_success(fn -> Event.emit(events) end)
          do
            {:ok, process}
          end
        end
      end

    end
  end

  defmacro connection(gateway, target, params, meta, do: block) do
    args = [gateway, target, params, meta]

    quote do
      defp get_connection(unquote_splicing(args)) do
        unquote(block)
      end
    end
  end

  defmacro objective(gateway, target, params, meta, do: block) do
    args = [gateway, target, params, meta]

    quote do
      defp get_objective(unquote_splicing(args)) do
        params = unquote(block)

        objective = call_process(:objective, params)

        %{objective: objective}
      end
    end
  end

  defmacro file(gateway, target, params, meta, do: block) do
    args = [gateway, target, params, meta]

    quote do
      defp get_file(unquote_splicing(args)) do
        file_id = unquote(block)

        %{file_id: file_id}
      end
    end
  end
end
