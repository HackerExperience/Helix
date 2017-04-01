defmodule Helix.Process.TestHelper.ProcessTypeExample do

  defstruct []

  defimpl Helix.Process.Model.Process.ProcessType do
    def dynamic_resources(_),
      do: [:cpu, :dlk, :ulk]
    def event(_, _, _),
      do: []
  end
end

defmodule Helix.Process.TestHelper.StaticProcessTypeExample do

  defstruct []

  defimpl Helix.Process.Model.Process.ProcessType do
    def dynamic_resources(_),
      do: []
    def event(_, _, _),
      do: []
  end
end
