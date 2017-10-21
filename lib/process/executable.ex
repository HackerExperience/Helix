# credo:disable-for-this-file Credo.Check.Refactor.CyclomaticComplexity
defmodule Helix.Process.Executable do

  alias Helix.Event
  alias Helix.Network.Action.Tunnel, as: TunnelAction
  alias Helix.Network.Query.Network, as: NetworkQuery
  alias Helix.Process.Action.Process, as: ProcessAction

  defmacro __using__(_args) do
    quote do

      import HELF.Flow
      import Helix.Process.Executable

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    quote do

      defp get_process_data(params) do
        data = call_process(:new, params)
        %{process_data: data}
      end

      defp get_ownership(gateway, target, params, meta) do
        %{
          gateway_id: gateway.server_id,
          target_server_id: target.server_id
        }
      end

      defp get_process_type(%{process_type: process_type}),
        do: %{process_type: process_type |> to_string()}
      defp get_process_type(_) do
        process_type = call_process(:get_process_type)
        %{process_type: @process_type}
      end

      defp get_network_id(%{network_id: network_id}),
        do: %{network_id: network_id}
      defp get_network_id(_),
        do: %{network_id: nil}

      defp call_process(function),
        do: apply(@process, function, [])
      defp call_process(function, params),
        do: apply(@process, function, [params])

      defp create_process_params(partial, %{connection_id: connection_id}),
        do: Map.put(partial, :connection_id, connection_id)
      defp create_process_params(partial, nil),
        do: Map.put(partial, :connection_id, nil)

      defp close_connection_on_fail(nil),
        do: :noop
      defp close_connection_on_fail(connection),
        do: TunnelAction.close_connection(connection)

      defp create_connection(network_id, gateway, target, bounce, type) do
        TunnelAction.connect(
          NetworkQuery.fetch(network_id),
          gateway.server_id,
          target.server_id,
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

        flowing do
          with \
            {:ok, connection, events} <- get_connection(unquote_splicing(args)),

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
      def get_connection(unquote_splicing(args)) do
        result = unquote(block)

        case result do
          {:ok, connection, events} ->
            {:ok, connection, events}

          :ok ->
            {:ok, nil, []}

          {:error, _} ->
            :terminate_connection
        end
      end
    end
  end

  defmacro objective(gateway, target, params, meta, do: block) do
    args = [gateway, target, params, meta]

    quote do
      def get_objective(unquote_splicing(args)) do
        params = unquote(block)

        objective = call_process(:objective, params)

        %{objective: objective}
      end
    end
  end

  defmacro file(gateway, target, params, meta, do: block) do
    args = [gateway, target, params, meta]

    quote do
      def get_file(unquote_splicing(args)) do
        file_id = unquote(block)

        %{file_id: file_id}
      end
    end
  end
end
