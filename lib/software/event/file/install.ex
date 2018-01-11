defmodule Helix.Software.Event.File.Install do

  import Helix.Event

  event Processed do

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
        backend: term  # TODO
      }

    @spec new(Process.t, FileInstallProcess.t) ::
      t
    def new(process = %Process{}, %FileInstallProcess{backend: backend}) do
      %__MODULE__{
        file: FileQuery.fetch(process.file_id),
        entity_id: process.source_entity_id,
        backend: backend
      }
    end
  end
end
