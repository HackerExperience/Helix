defmodule Helix.Software.Event.File.Install do

  import Helix.Event

  event Processed do
    @moduledoc """
    `FileInstallProcessedEvent` is fired when the FileInstallProcess has
    finished installing a file.

    It contains the `backend`, as defined at FileInstallProcess, so subscribers
    can figure out what type of file was installed (virus, firewall etc) and
    react accordingly.
    """

    alias Helix.Entity.Model.Entity
    alias Helix.Process.Model.Process
    alias Helix.Software.Model.File
    alias Helix.Software.Query.File, as: FileQuery
    alias Helix.Software.Process.File.Install, as: FileInstallProcess

    event_struct [:file, :entity_id, :backend]

    @type t ::
      %__MODULE__{
        file: File.t,
        entity_id: Entity.id,
        backend: FileInstallProcess.backend
      }

    @spec new(Process.t, FileInstallProcess.t) ::
      t
    def new(process = %Process{}, %FileInstallProcess{backend: backend}) do
      %__MODULE__{
        file: FileQuery.fetch(process.tgt_file_id),
        entity_id: process.source_entity_id,
        backend: backend
      }
      # Persist bounce data used by Loggable for proper logging
      |> put_bounce(process.bounce_id)

      # `FileInstallProcessedEvent` may be relayed to different backends, each
      # with their own internals. It may be overkill but here, have this process
      |> put_process(process)
    end
  end
end
