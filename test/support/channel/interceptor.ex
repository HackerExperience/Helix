defmodule Helix.Test.Channel.Interceptor do

  use GenServer

  @registry_name :channel_interceptor

  def start_link,
    do: GenServer.start_link(__MODULE__, %{}, name: @registry_name)

  def register_intercept(request_name, response) when is_tuple(response) do
    GenServer.call(
      @registry_name, {:register_intercept, request_name, response}
    )
  end

  def intercept(request_name),
    do: GenServer.call(@registry_name, {:intercept, request_name})

  def handle_call({:register_intercept, request_name, response}, _, state),
    do: {:reply, :ok, put_in(state, [request_name], response)}

  def handle_call({:intercept, request_name}, _, state) do
    # Get expected response
    response = Map.get(state, request_name)

    # No longer intercept the request
    new_state = Map.delete(state, request_name)

    {:reply, response, new_state}
  end
end
