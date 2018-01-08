import Helix.Process

process Helix.Software.Process.File.Install do

  alias Helix.Entity.Model.Entity
  alias Helix.Software.Model.File
  alias __MODULE__, as: FileInstallProcess

  alias Helix.Software.Event.File.Install.Processed,
    as: FileInstallProcessedEvent

  process_struct [:backend]

  @type backend :: [:virus]

  @type t ::
    %__MODULE__{
      backend: backend
    }

  @type resources ::
    %{
      objective: objective,
      l_dynamic: [:cpu],
      r_dynamic: [],
      static: map
    }

  @type creation_params :: %{backend: backend}

  @type objective :: %{cpu: resource_usage}

  @type resources_params ::
    %{
      file: File.t,
      backend: backend
    }

  def new(%{backend: backend}) do
    %__MODULE__{
      backend: backend
    }
  end

  def resources(params = %{file: %File{}, backend: _}),
    do: get_resources(params)

  processable do

    on_completion(process, data) do
      event = FileInstallProcessedEvent.new(process, data)

      {:delete, [event]}
    end

    def after_read_hook(data) do
      %FileInstallProcess{
        backend: String.to_existing_atom(data.backend)
      }
    end
  end

  resourceable do

    alias Helix.Software.Factor.File, as: FileFactor

    @type params :: FileInstallProcess.resources_params

    @type factors :: term

    get_factors(%{file: file, backend: _}) do

      # Retrieves information about the file to be installed
      factor FileFactor, %{file: file},
        only: [:version, :size]
    end

    # TODO: Use time as a resource instead. #364
    cpu(_) do
      30
    end

    dynamic do
      [:cpu]
    end
  end

  executable do

    @type params :: FileInstallProcess.creation_params

    @type meta :: term

    resources(_gateway, _target, %{backend: backend}, %{file: file}) do
      %{
        file: file,
        backend: backend
      }
    end

    file(_gateway, _target, _params, %{file: file}) do
      file.file_id
    end
  end

  process_viewable do

    @type data :: %{}

    render_empty_data()
  end
end
