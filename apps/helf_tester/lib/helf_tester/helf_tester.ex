defmodule HELM.HELFTester do
  use GenServer

  alias HELF.Tester

  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  def init([]) do
    {:ok, pid} = Tester.start_link(:tester_test)

    Tester.register(pid, "event:name", cast:
      fn msg when is_binary(msg) ->
        case msg do
          "a" -> :ok
          _ -> {:error, "Expected \"a\"."}
        end
      end)

    Tester.broker_cast(pid, "event:name", "a") # -> should pass
    #Tester.broker_cast(pid, "event:name", "b") # -> should fail and crash the server

    {:ok, %{}}
  end
end
