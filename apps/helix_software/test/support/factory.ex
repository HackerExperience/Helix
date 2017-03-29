defmodule Helix.Software.Factory do

  use ExMachina.Ecto, repo: Helix.Software.Repo

  alias HELL.PK
  alias HELL.TestHelper.Random
  alias Helix.Hardware.Model.Component
  alias Helix.Software.Model.StorageDrive
  alias Helix.Software.Model.SoftwareType

  def file_factory do
    :file
    |> prepare()
    |> Map.put(:storage, build(:storage))
  end

  def file_text_factory do
    %Helix.Software.Model.FileText{
      file: build(:file),
      contents: Burette.Color.name()
    }
  end

  def storage_drive_factory do
    :storage_drive
    |> prepare()
    |> Map.put(:storage, build(:storage))
  end

  def storage_factory do
    files = Random.repeat(1..3, fn -> prepare(:file) end)
    drives = Random.repeat(1..3, fn -> prepare(:storage_drive) end)

    %Helix.Software.Model.Storage{
      files: files,
      drives: drives
    }
  end

  defp prepare(:file) do
    # Maybe i need to add a generator for this in Burette
    path =
      1..5
      |> Random.repeat(fn -> Burette.Internet.username() end)
      |> Enum.join("/")

    size = Burette.Number.number(1024..1_048_576)
    name = Burette.Color.name()

    {software_type, _type_meta} = Enum.random(SoftwareType.possible_types())

    %Helix.Software.Model.File{
      name: name,
      file_path: "/" <> path,
      file_size: size,
      # FIXME: Think about a better way than hardcoding or fetching every time
      #   maybe have a genserver that holds all possibilities be started with
      #   the test suite, that way simply fetching it is faster (and allows
      #   hacks) than fetching from DB every time
      software_type: software_type
    }
  end

  defp prepare(:storage_drive),
    do: %StorageDrive{drive_id: PK.pk_for(Component)}
end
