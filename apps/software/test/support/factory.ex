defmodule Helix.Software.Factory do

  use ExMachina.Ecto, repo: Helix.Software.Repo

  alias HELL.PK
  alias HELL.TestHelper.Random
  alias Helix.Software.Model.Storage
  alias Helix.Software.Model.File

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

  def storage_factory do
    pk = PK.pk_for(Storage)

    files = Random.repeat(1..3, fn ->
      :file
      |> prepare()
      |> Map.put(:storage_id, pk)
    end)

    drives = Random.repeat(1..3, fn ->
      Helix.Software.Model.StorageDrive.create_changeset(%{storage_id: pk})
    end)

    %Helix.Software.Model.Storage{
      storage_id: pk,
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

    %Helix.Software.Model.File{
      file_id: PK.pk_for(File),
      name: Burette.Color.name(),
      file_path: path,
      file_size: size,
      # FIXME: Think about a better way than hardcoding or fetching every time
      #   maybe have a genserver that holds all possibilities be started with
      #   the test suite, that way simply fetching it is faster (and allows
      #   hacks) than fetching from DB every time
      file_type: Enum.random(["firewall", "cracker", "exploit", "hasher"])
    }
  end
end