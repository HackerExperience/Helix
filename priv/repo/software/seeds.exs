alias Helix.Software.Repo
alias Helix.Software.Model.SoftwareType
alias Helix.Software.Model.SoftwareModule

Repo.transaction fn ->
  Enum.each(SoftwareType.possible_types(), fn {type, %{extension: extension}} ->
    software_type = %SoftwareType{software_type: type, extension: extension}

    Repo.insert!(software_type, on_conflict: :nothing)
  end)

  Enum.each(SoftwareType.possible_types(), fn {type, %{modules: modules}} ->
    Enum.each(modules, fn module ->
      software_module = %SoftwareModule{
        software_type: type,
        module: module
      }

      Repo.insert!(software_module, on_conflict: :nothing)
    end)
  end)
end
