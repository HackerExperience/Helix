import Helix.Factor

factor Helix.Software.Factor.File do
  @moduledoc """
  `FileFactor` is responsible for gathering facts about the given file.
  """

  alias Helix.Software.Model.File

  @type factor ::
    %__MODULE__{
      size: fact_size,
      version: fact_version
    }

  @type fact_size :: File.size
  @type fact_version :: %{File.Module.name => File.Module.version}

  @type params :: term
  @type relay :: term

  factor_struct [:size, :version]

  fact(:size, %{file: file}, _relay) do
    set_fact file.file_size
  end

  fact(:version, %{file: file}, _relay) do
    file.modules
    |> Enum.reduce(%{}, fn {module, data}, acc ->
        Map.put(acc, module, data.version)
      end)
    |> set_fact
  end

  assembly do
    get_fact :size
    get_fact :version
  end
end
