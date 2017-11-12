defmodule Helix.Test.Client.Web1.Helper do

  alias Helix.Client.Web1.Model.Setup

  @pages Setup.valid_pages()

  def random_pages,
    do: [Enum.random(@pages)]
end
