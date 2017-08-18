defmodule Helix.Test.Software.Factory do

  import Ecto.Changeset

  alias Ecto.Changeset
  alias HELL.TestHelper.Random
  alias Helix.Hardware.Model.Component
  alias Helix.Software.Model.File
  alias Helix.Software.Model.Storage
  alias Helix.Software.Model.StorageDrive
  alias Helix.Software.Model.SoftwareType
  alias Helix.Software.Model.TextFile

  alias Helix.Software.Repo

  @type thing :: :file | :text_file | :storage | :storage_drive

  @spec changeset(thing, map | Keyword.t) ::
    Changeset.t
  def changeset(thing, params \\ %{}) do
    attrs =
      thing
      |> params_for()
      |> Map.merge(to_map(params))

    fabricate_changeset(thing, attrs)
  end

  @spec changeset_list(pos_integer, thing, map | Keyword.t) ::
    [Changeset.t, ...]
  def changeset_list(n, thing, params \\ %{}) when n >= 1 do
    for _ <- 1..n,
      do: changeset(thing, params)
  end

  @spec build(thing, map | Keyword.t) ::
    Ecto.Schema.t
  def build(thing, params \\ %{}) do
    thing
    |> changeset(params)
    |> ensure_valid_changeset()
    |> Ecto.Changeset.apply_changes()
  end

  @spec build_list(pos_integer, thing, map | Keyword.t) ::
    [Ecto.Schema.t, ...]
  def build_list(n, thing, params \\ %{}) when n >= 1 do
    for _ <- 1..n,
      do: build(thing, params)
  end

  @spec insert(thing, map | Keyword.t) ::
    Ecto.Schema.t
  def insert(thing, params \\ %{}) do
    thing
    |> changeset(params)
    |> Repo.insert!()
    |> preload_everything()
  end

  @spec insert_list(pos_integer, thing, map | Keyword.t) ::
    [Ecto.Schema.t, ...]
  def insert_list(n, thing, params \\ %{}) when n >= 1 do
    for _ <- 1..n,
      do: insert(thing, params)
  end

  @spec params_for(thing) ::
    map
  def params_for(:file) do
    {software_type, _} = Enum.random(SoftwareType.possible_types())

    path =
      1..5
      |> Random.repeat(fn -> Burette.Internet.username() end)
      |> Enum.join("/")

    %{
      storage: build(:storage),
      file_size: Enum.random(1024..1_048_576),
      name: Burette.Color.name(),
      software_type: software_type,
      path: path
    }
  end

  def params_for(:text_file) do
    Map.merge(%{contents: Burette.Color.name()}, params_for(:file))
  end

  def params_for(:storage) do
    %{}
  end

  def params_for(:storage_drive) do
    %{drive_id: Component.ID.generate()}
  end

  defp fabricate_changeset(:file, params = %{storage_id: _}) do
    params
    |> File.create_changeset()
    |> File.update_changeset(params)
    |> set_file_modules(params)
  end

  defp fabricate_changeset(:file, params) do
    params.storage
    |> File.create(params)
    |> File.update_changeset(params)
    |> set_file_modules(params)
  end

  defp fabricate_changeset(:text_file, params) do
    TextFile.create(params.storage, params.name, params.path, params.contents)
  end

  defp fabricate_changeset(:storage, params) do
    new_drive = fn -> [build(:storage_drive, storage: nil)] end
    drives = Map.get_lazy(params, :drives, new_drive)

    Storage.create_changeset()
    |> put_assoc(:drives, drives)
  end

  defp fabricate_changeset(:storage_drive, params = %{storage_id: _}) do
    StorageDrive.create_changeset(params)
  end

  defp fabricate_changeset(:storage_drive, params) do
    new_storage = fn -> changeset(:storage, drives: []) end
    storage = Map.get_lazy(params, :storage, new_storage)

    %StorageDrive{}
    |> cast(params, [:drive_id])
    |> put_assoc(:storage, storage)
  end

  defp set_file_modules(file_changeset, %{software_type: type}) do
    file_modules =
      SoftwareType.possible_types()
      |> Map.fetch!(type)
      |> Map.fetch!(:modules)
      |> Enum.map(&({&1, Enum.random(100..10_000)}))
      |> :maps.from_list()

    File.set_modules(file_changeset, file_modules)
  end

  defp to_map(x = %{}),
    do: x
  defp to_map(x) when is_list(x),
    do: :maps.from_list(x)

  defp ensure_valid_changeset(cs = %Ecto.Changeset{valid?: true}),
    do: cs
  defp ensure_valid_changeset(cs),
    do: raise "invalid changeset generated on factory: #{inspect cs}"

  defp preload_everything(struct) do
    Repo.preload(struct, struct.__struct__.__schema__(:associations))
  end
end
