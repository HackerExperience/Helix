defmodule Helix.Story.Mission.Tutorial do

  import Helix.Story.Step.Macros

  step SetupPC do

    email "welcome_pc_setup",
      reply: "back_thanks"

    on_reply "back_thanks",
      :complete

    setup entity_id do
      # Add char for player
      send_email "welcome_pc_setup", entity_id
    end

    def complete(step) do
      {:ok, step}
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

    setup entity_id do
      # Gero Servidor do Char
      # Gero FTP Public
      # Gero cracker
      send_email "download_cracker_public_ftp", entity_id, %{foo: :bar}

      {:ok, %{meta: :vai_aqui}}
    end

    def complete(step) do
      {:ok, step}
    end

    next_step __MODULE__

  end
end
