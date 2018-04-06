defmodule Helix.Story.Mission.Tutorial do

  import Helix.Story.Model.Step.Macros

  contact :friend

  step SetupPc do

    email "welcome",
      replies: "back_thanks"

    on_reply "back_thanks",
      send: "watchiadoing"

    email "watchiadoing",
      replies: "hell_yeah"

    on_reply "hell_yeah",
      do: :complete

    empty_setup()

    def start(step) do
      e1 = send_email step, "welcome"

      {:ok, step, e1, []}
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
    alias Helix.Software.Event.File.Deleted, as: FileDeletedEvent

    alias Helix.Software.Make.File, as: MakeFile
    alias Helix.Software.Make.PFTP, as: MakePFTP

    email "download_cracker1"

    email "about_that",
      replies: ["yeah_right"]

    on_email "about_that",
      reply: "yeah_right",
      send_opts: [sleep: 2]

    reply "yeah_right",
      replies: "downloaded"

    reply "downloaded",
      replies: ["nothing_now"]

    on_reply "downloaded",
      send: "nothing_now",
      send_opts: [sleep: 5]

    email "nothing_now"

    on_email "nothing_now",
      do: :complete,
      send_opts: [sleep: 3]

    def setup(step) do
      # Create the underlying character (@contact) and its server
      {:ok, server, _, e1} =
        setup_once :char, {step.entity_id, @contact} do
          result = {:ok, server, %{entity: entity}, _} =
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

      # Enable the PFTP server
      {:ok, pftp, _, e3} =
        setup_once :pftp_server, server do
          MakePFTP.server(server)
        end

      # Make the Cracker available for download on the PFTP server
      {:ok, _, _, e4} =
        setup_once :pftp_file, cracker do
          MakePFTP.add_file(cracker, pftp)
        end

      meta =
        %{
          ip: ServerQuery.get_ip(server, step.manager.network_id),
          server_id: server.server_id,
          cracker_id: cracker.file_id
        }

      # Listeners
      hespawn fn ->

        # Send `about_that` when download starts
        on_download_started cracker.file_id, email: "about_that", sleep: 2

        # Reply `downloaded` when the cracker has been downloaded
        story_listen cracker.file_id, FileDownloadedEvent, reply: "downloaded"

        story_listen cracker.file_id, FileDeletedEvent, :on_file_deleted

      end

      {meta, %{}, e1 ++ e2 ++ e3 ++ e4}
    end

    # Callbacks

    callback :on_file_deleted, _event do
      {{:restart, :file_deleted, "download_cracker1"}, []}
    end

    def start(step) do
      {meta, _, e1} = setup(step)

      e2 = send_email step, "download_cracker1", %{ip: meta.ip}

      step = %{step| meta: meta}

      {:ok, step, e1 ++ e2, sleep: 4}
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

    def restart(step, _reason, _checkpoint) do
      {meta, _, e1} = setup(step)

      {:ok, %{step| meta: meta}, %{ip: meta.ip}, e1}
    end

    next_step Helix.Story.Mission.Tutorial.NastyVirus
  end

  step NastyVirus do

    alias Helix.Server.Model.Server
    alias Helix.Server.Query.Server, as: ServerQuery
    alias Helix.Software.Model.File
    alias Helix.Story.Action.Context, as: ContextAction

    alias Helix.Client.Event.Action.Performed, as: ClientActionPerformedEvent
    alias Helix.Server.Event.Server.Password.Acquired,
      as: ServerPasswordAcquiredEvent

    alias Helix.Software.Make.File, as: MakeFile

    email "nasty_virus1"

    on_email "nasty_virus1",
      send: "nasty_virus2",
      send_opts: [sleep: 3]

    email "nasty_virus2",
      replies: "punks1"

    email "punks2"

    on_reply "punks1",
      send: "punks2",
      send_opts: [sleep: 3]

    email "punks3"

    filter_email "punks2" do
      {{:send_email, "punks3", %{ip: step.meta.ip}, [sleep: 2]}, step, []}
    end

    email "dlayd_much1",
      replies: "dlayd_much2"

    email "dlayd_much3"

    on_reply "dlayd_much2",
      send: "dlayd_much3",
      send_opts: [sleep: 2]

    email "dlayd_much4",
      replies: "noice"

    on_email "dlayd_much4",
      reply: "noice",
      send_opts: [sleep: 2]

    email "nasty_virus3",
      replies: ["virus_spotted1"]

    reply "virus_spotted1"

    on_reply "virus_spotted1",
      send: "virus_spotted2",
      send_opts: [sleep: 2]

    email "virus_spotted2",
      replies: ["pointless_convo1"]

    reply "pointless_convo1"

    on_reply "pointless_convo1",
      send: "pointless_convo2",
      send_opts: [sleep: 3]

    email "pointless_convo2",
      replies: ["pointless_convo3"]

    on_email "pointless_convo2",
      reply: "pointless_convo3",
      send_opts: [sleep: 3]

    reply "pointless_convo3"

    on_reply "pointless_convo3",
      send: "pointless_convo4",
      send_opts: [sleep: 4]

    email "pointless_convo4",
      replies: ["pointless_convo5"]

    on_email "pointless_convo4",
      reply: "pointless_convo5",
      send_opts: [sleep: 2]

    def setup(step) do
      # Create the underlying character (:rcn) and its server
      {:ok, server, _, e1} =
        setup_once :char, {step.entity_id, :rcn} do
          result = {:ok, server, %{entity: entity}, _} =
            StoryMake.char(step.manager.network_id)

          ContextAction.save(
            step.entity_id, :rcn, :server_id, server.server_id
          )
          ContextAction.save(
            step.entity_id, :rcn, :entity_id, entity.entity_id
          )

          result
        end

      # Create the Spyware the player is supposed to download
      {:ok, spyware, _, e2} =
        setup_once :file, step.meta[:spyware_id] do
          result = {:ok, spyware, _, _} =
            MakeFile.spyware(server, %{vir_spyware: 30})

          ContextAction.save(
            step.entity_id, :rcn, :spyware_id, spyware.file_id
          )

          result
        end

      meta =
        %{
          ip: ServerQuery.get_ip(server, step.manager.network_id),
          server_id: server.server_id,
          spyware_id: spyware.file_id
        }

      # Listeners
      hespawn fn ->

        # Send `dlayd_much1` when bruteforce starts
        on_bruteforce_started server.server_id, email: "dlayd_much1", sleep: 2

        # Send `nasty_virus3` when bruteforce finishes
        story_listen server.server_id, ServerPasswordAcquiredEvent,
          email: "nasty_virus3", sleep: 2

        # Send `pointless_convo1` when download starts
        on_download_started spyware.file_id, reply: "pointless_convo1", sleep: 2

      end

      {meta, %{}, e1 ++ e2}
    end

    # Filters

    # Send `dlayd_much4` email when player opens TaskManager app
    filter(
      _step,
      %ClientActionPerformedEvent{
        client: _,
        action: :tutorial_accessed_task_manager
      },
      _meta,
      send: "dlayd_much4", send_opts: [sleep: 1]
    )

    # Send `virus_spotted1` reply when player spots the virus
    filter(
      _step,
      %ClientActionPerformedEvent{
        client: _,
        action: :tutorial_spotted_nasty_virus
      },
      _meta,
      reply: "virus_spotted1", send_opts: [sleep: 1]
    )

    def start(step) do
      {meta, _, e1} = setup(step)

      e2 = send_email step, "nasty_virus1", %{}

      step = %{step| meta: meta}

      {:ok, step, e1 ++ e2, sleep: 4}
    end

    def complete(step) do
      {:ok, step, []}
    end

    format_meta do
      %{
        ip: meta.ip,
        server_id: meta.server_id |> Server.ID.cast!(),
        spyware_id: meta.spyware_id |> File.ID.cast!()
      }
    end

    next_step __MODULE__

  end
end
