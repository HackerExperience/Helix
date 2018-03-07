defmodule Helix.Test.Channel.Interceptor do

  use GenServer

  @registry_name :channel_interceptor

  # External API

  def start_link,
    do: GenServer.start_link(__MODULE__, %{}, name: @registry_name)

  def intercept_once(endpoint, response),
    do: add_intercept(endpoint, response, :once)

  def intercept_forever(endpoint, response),
    do: add_intercept(endpoint, response, :forevis)

  def stop_intercept(endpoint),
    do: GenServer.call(@registry_name, {:stop_intercept, endpoint})

  defp add_intercept(endpoint, response, lifetime) when is_tuple(response) do
    GenServer.call(
      @registry_name, {:add_intercept, endpoint, {response, lifetime}}
    )
  end

  def intercept(endpoint),
    do: GenServer.call(@registry_name, {:intercept, endpoint})

  # Callbacks

  def init(_),
    do: {:ok, []}

  def handle_call({:add_intercept, endpoint, entry}, _, state),
    do: {:reply, :ok, put_in(state, [endpoint], entry)}

  def handle_call({:stop_intercept, endpoint}, _, state),
    do: {:reply, :ok, remove_entry(state, endpoint)}

  def handle_call({:intercept, endpoint}, _, state) do
    case Map.get(state, endpoint) do
      {response, :once} ->
        {:reply, response, remove_entry(state, endpoint)}

      {response, :forevis} ->
        {:reply, response, state}

      nil ->
        {:reply, nil, state}
    end
  end

  defp remove_entry(state, endpoint),
    do: Map.delete(state, endpoint)
end
