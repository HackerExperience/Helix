defmodule Helix.Process.TestHelper.SoftwareTypeExample do

  defstruct []

  defimpl Helix.Process.Model.Process.SoftwareType do
    def allocation_handler(_),
      do: nil
    def flow_handler(_),
      do: nil
    def event_namespace(_),
      do: nil
  end
end