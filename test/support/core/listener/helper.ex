defmodule Helix.Test.Core.Listener.Helper do

  alias HELL.TestHelper.Random

  def random_object_id,
    do: Random.string(min: 8, max: 32)

  def random_event,
    do: Random.string(min: 8)

  def random_callback do
    module = Random.string(min: 8)
    method = Random.string(min: 3, max: 8)

    {module, method}
  end
end
