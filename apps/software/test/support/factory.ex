defmodule Helix.Software.Factory do

  use ExMachina.Ecto, repo: Helix.Software.Repo

  alias HELL.PK
  alias HELL.TestHelper.Random

  def file_factory do
    :file
    |> prepare()
    |> Map.put(:storage, build(:storage))
  end

  def storage_factory do
    pk = PK.generate([0x0004, 0x0001, 0x0000])

    files = Random.repeat(1..3, fn ->
      :file
      |> prepare()
      |> Map.put(:storage_id, pk)
    end)

    drive_amount = Burette.Number.number(1..3)
    drives = for i <- 1..drive_amount do
      %{drive_id: i, storage_id: pk}
    end

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
      file_id: PK.generate([0x0004, 0x0000, 0x0000]),
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