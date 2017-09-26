defmodule Helix.Story.Mission.Tutorial do

  import Helix.Story.Model.Step.Macros

  contact :friend

  step SetupPC do

    email "welcome_pc_setup",
      reply: "back_thanks"

    on_reply "back_thanks",
      :complete

    def setup(step, _) do
      e1 = send_email step, "welcome_pc_setup"

      {:ok, step, e1}
    end

    def complete(step) do
      {:ok, step, []}
    end

    next_step Helix.Story.Mission.Tutorial.DownloadCrackerPublicFTP
  end

  step DownloadCrackerPublicFTP do

    email "download_cracker_public_ftp",
      reply: ["more_info"],
      locked: ["sure"]

    email "give_more_info",
      reply: ["sure"],
      locked: ["more_info"]

    on_reply "more_info",
      send: "give_more_info"

    def setup(step, _) do
      # Gero Servidor do Char
      # Gero FTP Public
      # Gero cracker
      e1 = send_email step, "download_cracker_public_ftp", %{foo: :bar}

      {:ok, step, e1}
    end

    def complete(step) do
      {:ok, step, []}
    end

    next_step __MODULE__
  end
end
