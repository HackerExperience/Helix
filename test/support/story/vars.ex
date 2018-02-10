defmodule Helix.Test.Story.Vars do
  @moduledoc """
  This helper will inject (in a non-higienic way!)
  """

  @vars %{
    contact: %{
      friend: "friend"
    },
    step: %{
      setup_pc: %{
        name: "setup_pc",
        next: "download_cracker",
        msg1: "welcome",
        msg2: "back_thanks",
        msg3: "watchiadoing",
        msg4: "hell_yeah",
      }
    }
  }

  def vars,
    do: @vars
end
