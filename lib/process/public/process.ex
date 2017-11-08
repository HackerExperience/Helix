defmodule Helix.Process.Public.Process do

  alias Helix.Process.Model.Process
  alias Helix.Process.Action.Flow.Process, as: ProcessFlow

  @spec kill(Process.t, Process.kill_reason) ::
    {:ok, Process.t}
  @doc """
  Sends a SIGKILL to the `process` with the given `reason`
  """
  def kill(process = %Process{}, reason),
    do: ProcessFlow.signal(process, :SIGKILL, %{reason: reason})
end
