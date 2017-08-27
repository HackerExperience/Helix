defmodule Helix.Test.Software.Helper do

  alias Helix.Software.Model.SoftwareType

  alias HELL.TestHelper.Random

  @doc """
  Generates the expected module for the given type.

  Example of expected input:
    (:cracker, %{bruteforce: 20, overflow: 10})
  """
  def generate_module(type, version_map) do
    modules = SoftwareType.possible_types()[type].modules

    Enum.reduce(modules, %{}, fn (module, acc) ->
      Map.put(acc, module, Map.fetch!(version_map, module))
    end)
  end

  @doc """
  Returns modules with random versions for the given file.
  """
  def get_modules(type) do
    modules = SoftwareType.possible_types()[type].modules

    Enum.reduce(modules, %{}, fn (module, acc) ->
      Map.put(acc, module, random_version())
    end)
  end

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

  def random_version,
    do: 10
end
