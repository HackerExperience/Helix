defmodule Helix.Maroto do
  @moduledoc """
  Use Helix.Maroto and smile!

  (Sorriso maroto)
  """

  defmacro __using__(_) do
    quote do

      use Helix.Maroto.Aliases
      use Helix.Maroto.Functions

      :noix

    end
  end

end
