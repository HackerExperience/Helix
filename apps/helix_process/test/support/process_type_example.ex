defmodule Helix.Process.TestHelper.ProcessTypeExample do

  defstruct []

  defimpl Helix.Process.Model.Process.ProcessType do
    def dynamic_resources(_),
      do: [:cpu, :dlk, :ulk]
    def event_namespace(_),
      do: "event:process:test:completed"
  end
end

defmodule Helix.Process.TestHelper.StaticProcessTypeExample do

  defstruct []

  defimpl Helix.Process.Model.Process.ProcessType do
    def dynamic_resources(_),
      do: []
    def event_namespace(_),
      do: "event:process:statictest:completed"
  end
end