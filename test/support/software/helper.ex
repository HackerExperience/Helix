defmodule Helix.Test.Software.Helper do

  alias Helix.Software.Model.SoftwareType

  alias HELL.TestHelper.Random

  def random_file_name do
    Burette.Color.name()
  end

  def random_file_path do
    1..5
    |> Random.repeat(fn -> Burette.Internet.username() end)
    |> Enum.join("/")
  end

  def random_file_type do
    {software_type, _} = Enum.random(SoftwareType.possible_types())
    software_type
  end
end
