defmodule Helix.Test.Process.FakeProcess do

  import Helix.Process

  process FakeFileTransfer do

    process_objective do

      @type params :: term
      @type factors :: term

      get_factors(_) do
        :noop
      end

      dlk(%{type: :download}) do
        100
      end

      ulk(%{type: :upload}) do
        100
      end

      dlk(%{type: :upload})
      ulk(%{type: :download})

      def dynamic(%{type: :download}) do
        [:dlk]
      end

      def dynamic(%{type: :upload}) do
        [:ulk]
      end

    end

  end

end
