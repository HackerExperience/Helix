defmodule Helix.Test.Network.Helper.Bounce do

  alias Helix.Network.Model.Bounce

  alias HELL.TestHelper.Random
  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Network.Helper, as: NetworkHelper

  @internet_id NetworkHelper.internet_id()

  @doc """
  Generates a random name for the bounce
  """
  def name,
    do: Random.string(min: 4, max: 20)

  @doc """
  Generates `n` fake links
  """
  def links(total: n),
    do: Enum.map(1..n, fn _ -> fake_link() end)

  @doc """
  Generates a fake link
  """
  def fake_link,
    do: {ServerHelper.id(), @internet_id, Random.ipv4()}

  @doc """
  Generates a bounce ID
  """
  def id,
    do: Bounce.ID.generate(%{}, :bounce)
end
