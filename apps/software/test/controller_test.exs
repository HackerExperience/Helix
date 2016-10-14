defmodule HELM.Software.ControllerTest do
  use ExUnit.Case

  alias HELF.Broker

  def random_num do
    :rand.uniform(134217727)
  end

  def random_str do
    random_num()
    |> Integer.to_string
  end
end
