defmodule Helix.Process.TestHelper.SoftwareTypeExample do

  defstruct []

  defimpl Helix.Process.Model.Process.SoftwareType do
    def dynamic_resources(_),
      do: [:cpu, :dlk, :ulk]
    def event_namespace(_),
      do: "event:process:test:completed"
  end
end

defmodule Helix.Process.TestHelper.StaticSoftwareTypeExample do

  defstruct []

  defimpl Helix.Process.Model.Process.SoftwareType do
    def dynamic_resources(_),
      do: []
    def event_namespace(_),
      do: "event:process:statictest:completed"
  end
end