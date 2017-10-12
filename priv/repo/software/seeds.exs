alias Helix.Software.Repo
alias Helix.Software.Model.Software

Repo.transaction fn ->
  all_software = Software.all()

  # Stores all software information (type and module)
  Enum.each(all_software, fn software ->
    # Insert software type entry
    software
    |> Software.Type.create_changeset()
    |> Repo.insert!(on_conflict: :nothing)

    # Insert entry for all modules that belong to this software
    Enum.each(software.modules, fn module ->
      params = %{
        software_type: software.type,
        module: module
      }

      params
      |> Software.Module.create_changeset()
      |> Repo.insert!(on_conflict: :nothing)
    end)
  end)
end
