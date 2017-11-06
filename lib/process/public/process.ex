defmodule Helix.Process.Public.Process do

  alias Helix.Process.Model.Process
  alias Helix.Process.Action.Flow.Process, as: ProcessFlow

  def kill(process = %Process{}, reason),
    do: ProcessFlow.signal(process, :SIGKILL, %{reason: reason})
end
