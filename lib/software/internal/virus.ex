defmodule Helix.Software.Internal.Virus do

  alias Helix.Entity.Model.Entity
  alias Helix.Software.Model.File
  alias Helix.Software.Model.Virus
  alias Helix.Software.Repo

  @spec fetch(File.id) ::
    Virus.t
    | nil
  def fetch(file_id) do
    virus =
      file_id
      |> Virus.Query.by_file()
      |> Virus.Query.join_active()
      |> Repo.one()

    with %{} <- virus do
      Virus.format(virus)
    end
  end

  @spec is_active?(File.id) ::
    boolean
  def is_active?(virus_id) do
    active =
      virus_id
      |> Virus.Active.Query.by_virus()
      |> Repo.one()

    active
    && true
    || false
  end

  @spec install(File.t, Entity.id) ::
    {:ok, Virus.t}
    | {:error, :internal}
  def install(file = %File{}, entity_id) do
    Repo.transaction fn ->
      with \
        {:ok, virus} <- insert_virus(file, entity_id),
        {:ok, _} <- try_activate_virus(virus)
      do
        # We have to query the virus we just inserted because... from Ecto doc:
        # "Because we used on_conflict: :nothing, instead of getting an error,
        # we got {:ok, struct}. However the returned struct does not reflect the
        # data in the database."
        # Yeah.
        virus
        |> Repo.preload(:active)
        |> Virus.format()
      else
        _ ->
          Repo.rollback(:internal)
      end
    end
  end

  @spec activate_virus(Virus.t) ::
    {:ok, Virus.t}
    | {:error, Virus.changeset}
  def activate_virus(virus = %Virus{}) do
    result = force_activate_virus(virus)

    # See `install/2` comments on why we have to fetch again.
    with {:ok, _} <- result do
      {:ok, fetch(virus.file_id)}
    end
  end

  @spec insert_virus(File.t, Entity.id) ::
    {:ok, Virus.t}
    | {:error, Virus.changeset}
  defp insert_virus(file, entity_id) do
    %{
      file_id: file.file_id,
      entity_id: entity_id,
      storage_id: file.storage_id
    }
    |> Virus.create_changeset()
    |> Repo.insert()
  end

  @spec try_activate_virus(Virus.t) ::
    {:ok, Virus.t}
    | {:error, Virus.changeset}
  defp try_activate_virus(virus = %Virus{}) do
    virus
    |> Virus.Active.create_from_virus()
    |> Repo.insert(on_conflict: :nothing)
  end

  @spec force_activate_virus(Virus.t) ::
    {:ok, Virus.t}
    | {:error, Virus.changeset}
  defp force_activate_virus(virus = %Virus{}) do
    virus
    |> Virus.Active.create_from_virus()
    |> Repo.insert(
      on_conflict: :replace_all, conflict_target: [:entity_id, :storage_id]
    )
  end
end
