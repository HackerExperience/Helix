defmodule Helix.Story.Mission.Tutorial do

  import Helix.Story.Model.Step.Macros

  contact :friend

  step SetupPc do

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

    next_step Helix.Story.Mission.Tutorial.DownloadCrackerPublicFtp
  end

  step DownloadCrackerPublicFtp do

    alias Helix.Server.Model.Server
    alias Helix.Server.Query.Server, as: ServerQuery
    alias Helix.Software.Model.File
    alias Helix.Story.Action.Context, as: ContextAction

    alias Helix.Software.Event.File.Downloaded, as: FileDownloadedEvent

    alias Helix.Software.Make.File, as: MakeFile
    alias Helix.Software.Make.PFTP, as: MakePFTP

    email "download_cracker_public_ftp",
      reply: ["more_info"],
      locked: ["sure"]

    email "give_more_info",
      reply: ["sure"],
      locked: ["more_info"]

    on_reply "more_info",
      send: "give_more_info"

    def setup(step, _) do
      {:ok, server, %{entity: entity}} = StoryMake.char(step.manager.network_id)

      ContextAction.save(step.entity_id, @contact, :server_id, server.server_id)
      ContextAction.save(step.entity_id, @contact, :entity_id, entity.entity_id)

      # Create the Cracker the player is supposed to download
      cracker = MakeFile.cracker!(server, %{bruteforce: 10, overflow: 10})

      # Enable a PFTP server and put the cracker in it
      {:ok, pftp, _} = MakePFTP.server(server)
      MakePFTP.add_file(cracker, pftp)

      ip = ServerQuery.get_ip(server, step.manager.network_id)

      meta =
        %{
          ip: ip,
          server_id: server.server_id,
          cracker_id: cracker.file_id
        }

      # Callbacks

      # React to the moment the cracker is downloaded
      story_listen cracker.file_id, FileDownloadedEvent, do: :complete

      e1 = send_email step, "download_cracker_public_ftp", %{ip: ip}

      step = %{step|meta: meta}

      {:ok, step, e1}
    end

    format_meta do
      %{
        ip: meta.ip,
        server_id: meta.server_id |> Server.ID.cast!(),
        cracker_id: meta.cracker_id |> File.ID.cast!()
      }
    end

    def complete(step) do
      {:ok, step, []}
    end

    next_step __MODULE__
  end
end
