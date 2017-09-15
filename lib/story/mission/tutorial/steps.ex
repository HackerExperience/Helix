defmodule Helix.Story.Mission.Tutorial do

  import Helix.Story.Step.Macros

  step SetupPC do

    def filter_event(step) do
      {:ok, step}
    end

    def complete(step) do
      {:ok, step}
    end

    next_step Helix.Story.Mission.Tutorial.SetupPC
  end
end
