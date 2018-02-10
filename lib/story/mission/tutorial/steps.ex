defmodule Helix.Story.Mission.Tutorial do

  import Helix.Story.Model.Step.Macros

  contact :friend

  step SetupPc do

    email "welcome",
      reply: "back_thanks"

    on_reply "back_thanks",
      send: "watchiadoing"

    email "watchiadoing",
      reply: "hell_yeah"

    on_reply "hell_yeah",
      :complete

    empty_setup()

    def start(step, _) do
      e1 = send_email step, "welcome"

      {:ok, step, e1}
    end

    def complete(step) do
      {:ok, step, []}
    end

    next_step Helix.Story.Mission.Tutorial.DownloadCracker
  end

  step DownloadCracker do

    alias Helix.Server.Model.Server
    alias Helix.Server.Query.Server, as: ServerQuery
    alias Helix.Software.Model.File
    alias Helix.Story.Action.Context, as: ContextAction

    alias Helix.Software.Event.File.Downloaded, as: FileDownloadedEvent

    alias Helix.Software.Make.File, as: MakeFile
    alias Helix.Software.Make.PFTP, as: MakePFTP

    email "download_cracker1",
      reply: ["more_info"],
      locked: ["sure"]

    email "give_more_info",
      reply: ["sure"],
      locked: ["more_info"]

    on_reply "more_info",
      send: "give_more_info"

    def setup(step, _) do
      # Create the underlying character (@contact) and its server
      {:ok, server, %{entity: entity}, e1} =
        setup_once :char, {step.entity_id, @contact} do
          result = {:ok, server, %{entity: entity}, events} =
            StoryMake.char(step.manager.network_id)

          ContextAction.save(
            step.entity_id, @contact, :server_id, server.server_id
          )
          ContextAction.save(
            step.entity_id, @contact, :entity_id, entity.entity_id
          )

          result
        end

      # Create the Cracker the player is supposed to download
      {:ok, cracker, _, e2} =
        setup_once :file, step.meta[:cracker_id] do
          MakeFile.cracker(server, %{bruteforce: 10, overflow: 10})
        end

      # Enable the PFTP server and put the cracker in it
      {:ok, pftp, _, e3} =
        setup_once :pftp_server, server do
          MakePFTP.server(server)
        end

      {:ok, _, _, e4} =
        setup_once :pftp_file, cracker do
          MakePFTP.add_file(cracker, pftp)
        end

      ip = ServerQuery.get_ip(server, step.manager.network_id)

      meta =
        %{
          ip: ip,
          server_id: server.server_id,
          cracker_id: cracker.file_id
        }

      # Callbacks
      hespawn fn ->

        # React to the moment the cracker is downloaded
        story_listen cracker.file_id, FileDownloadedEvent, do: :complete
      end

      events = e1 ++ e2 ++ e3 ++ e4

      {meta, %{}, events}
    end

    def start(step, prev_step) do
      {meta, _, e1} = setup(step, prev_step)

      e2 = send_email step, "download_cracker1", %{ip: meta.ip}

      step = %{step|meta: meta}

      {:ok, step, e1 ++ e2}
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

    next_step Helix.Story.Mission.Tutorial.SetupPc
  end
end
