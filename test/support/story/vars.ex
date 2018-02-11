defmodule Helix.Test.Story.Vars do
  @moduledoc """
  This helper holds storyline-wide IDs and pointers. Helpful to avoiding
  hard-coding stuff on the tests!
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
