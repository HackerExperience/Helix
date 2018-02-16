defmodule Helix.Software.Internal.Virus do

  alias HELL.Utils
  alias Helix.Entity.Model.Entity
  alias Helix.Software.Model.File
  alias Helix.Software.Model.Storage
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

  @spec is_active?(File.idt) ::
    boolean
  @doc """
  Checks whether the given virus is active
  """
  def is_active?(file = %File{}),
    do: is_active?(file.file_id)
  def is_active?(virus_id) do
    active =
      virus_id
      |> Virus.Active.Query.by_virus()
      |> Repo.one()

    active
    && true
    || false
  end

  @spec list_by_storage(Storage.idt) ::
    [Virus.t]
  @doc """
  Returns a list of viruses on the given storage.
  """
  def list_by_storage(storage) do
    storage
    |> Virus.Query.by_storage()
    |> Virus.Query.join_active()
    |> Repo.all()
    |> Enum.map(&Virus.format/1)
  end

  @spec list_by_entity(Entity.idt) ::
    [Virus.t]
  @doc """
  Returns a list of viruses installed by the given entity.
  """
  def list_by_entity(entity) do
    entity
    |> Virus.Query.by_entity()
    |> Virus.Query.join_active()
    |> Repo.all()
    |> Enum.map(&Virus.format/1)
  end

  @spec list_by_storage_and_entity(Storage.idt, Entity.idt) ::
    [Virus.t]
  @doc """
  Returns a list of viruses installed by the given entity on the given storage.
  """
  def list_by_storage_and_entity(storage, entity) do
    storage
    |> Virus.Query.by_storage_and_entity(entity)
    |> Virus.Query.join_active()
    |> Repo.all()
    |> Enum.map(&Virus.format/1)
  end

  @spec entity_has_virus_on_storage?(Entity.idt, Storage.idt) ::
    boolean
  @doc """
  Checks whether the given entity has any virus installed on the given storage.

  It's basically a wrapper to `list_by_storage_and_entity/2`.
  """
  def entity_has_virus_on_storage?(entity = %Entity{}, storage),
    do: entity_has_virus_on_storage?(entity.entity_id, storage)
  def entity_has_virus_on_storage?(entity_id, storage) do
    storage
    |> list_by_storage_and_entity(entity_id)
    |> Enum.any?(&(&1.entity_id == entity_id))
  end

  @spec install(File.t, Entity.id) ::
    {:ok, Virus.t}
    | {:error, :internal}
  @doc """
  Installs a virus. Automatically activates it (if it's the first virus from
  that entity on the given storage).
  """
  def install(file = %File{}, entity_id) do
    Repo.transaction fn ->
      with \
        {:ok, virus} <- insert_virus(file, entity_id),
        {:ok, _} <- try_activate_virus(virus, file.storage_id)
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

  @spec activate_virus(Virus.t, Storage.id) ::
    {:ok, Virus.t}
    | {:error, Virus.changeset}
  @doc """
  Activates the given virus, deactivating whatever virus was previously active.
  """
  def activate_virus(virus = %Virus{}, storage_id = %Storage.ID{}) do
    result = force_activate_virus(virus, storage_id)

    # Review: really? because comment says only `:nothing`
    # See `install/2` comments on why we have to fetch again.
    with {:ok, _} <- result do
      {:ok, fetch(virus.file_id)}
    end
  end

  @spec set_running_time(Virus.t, seconds :: integer) ::
    {:ok, Virus.t}
    | {:error, :internal}
  @doc """
  Modifies the virus running time. If `seconds` is 0, it will reset to the
  current time. This is the most common scenario, and it's the one used when the
  virus is collected.

  A positive `seconds` will push the `running_time` towards the future, and a
  negative one will push the `running_time` to the past. The latter is useful
  for compensating a failed virus collect (albeit uncommon).
  """
  def set_running_time(virus = %Virus{}, seconds) do
    new_time = Utils.date_before(seconds)

    case update_activation_time(virus, new_time) do
      {1, _} ->
        {:ok, fetch(virus.file_id)}

      _ ->
        {:error, :internal}
    end
  end

  @spec insert_virus(File.t, Entity.id) ::
    {:ok, Virus.t}
    | {:error, Virus.changeset}
  defp insert_virus(file, entity_id) do
    %{
      file_id: file.file_id,
      entity_id: entity_id
    }
    |> Virus.create_changeset()
    |> Repo.insert()
  end

  @spec try_activate_virus(Virus.t, Storage.id) ::
    {:ok, Virus.t}
    | {:error, Virus.changeset}
  defp try_activate_virus(virus = %Virus{}, storage_id = %Storage.ID{}) do
    virus
    |> Virus.Active.create(storage_id)
    |> Repo.insert(on_conflict: :nothing)
  end

  @spec force_activate_virus(Virus.t, Storage.id) ::
    {:ok, Virus.t}
    | {:error, Virus.changeset}
  defp force_activate_virus(virus = %Virus{}, storage_id = %Storage.ID{}) do
    virus
    |> Virus.Active.create(storage_id)
    |> Repo.insert(
      on_conflict: :replace_all, conflict_target: [:entity_id, :storage_id]
    )
  end

  @spec update_activation_time(Virus.t, new_time :: DateTime.t) ::
    {integer, nil}
    | :no_return
  defp update_activation_time(virus = %Virus{}, new_time) do
    virus.file_id
    |> Virus.Active.Query.by_virus()
    |> Repo.update_all(set: [activation_time: new_time])
  end
end
