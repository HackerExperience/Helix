defmodule Helix.Test.Story.Vars do
  @moduledoc """
  This helper holds storyline-wide IDs and pointers. Helpful to avoiding
  hard-coding stuff on the tests!
  """

  @vars %{
    contact: %{
      friend: "friend"
    },
    tutorial: %{
      setup: %{
        contact: "friend",
        name: "setup_pc",
        next: "download_cracker",
        msg1: "welcome",
        msg2: "back_thanks",
        msg3: "watchiadoing",
        msg4: "hell_yeah",
      },
      dl_crc: %{
        contact: "friend",
        name: "download_cracker",
        next: "nasty_virus",
        msg1: "download_cracker1",
        msg2: "about_that",
        msg3: "yeah_right",
        msg4: "downloaded",
        msg5: "nothing_now"
      }
    }
  }

  def vars,
    do: @vars
end
