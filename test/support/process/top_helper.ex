defmodule Helix.Test.Process.TOPHelper do

  alias Helix.Server.Model.Server
  alias Helix.Process.State.TOP.Manager, as: TOPManager

  def top_stop(server) do
    server
    |> Server.ID.cast!()
    |> TOPManager.get()
    |> its_time_to_stop()
  end

  defp its_time_to_stop(nil),
    do: :ok
  defp its_time_to_stop(pid),
    do: GenServer.stop(pid)
end
