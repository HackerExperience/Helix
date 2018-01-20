defmodule Helix.Test.Network.Setup.Bounce do

  alias Ecto.Changeset
  alias Helix.Network.Model.Bounce
  alias Helix.Network.Repo, as: NetworkRepo

  alias HELL.TestHelper.Random
  alias Helix.Test.Entity.Setup, as: EntitySetup
  alias Helix.Test.Network.Helper, as: NetworkHelper

  @doc """
  See docs on `fake_bounce/1`
  """
  def bounce(opts \\ []) do
    {
      bounce,
      related = %{changeset: changeset, entries: entries, sorted: sorted}
    } =
      fake_bounce(opts)

    NetworkRepo.insert!(changeset)
    Enum.each(entries, &NetworkRepo.insert!/1)

    {bounce, related}
  end

  @doc """
  - bounce_id: Set bounce id.
  - entity_id: Set entity who owns the bounce.
  - name: Set bounce name.
  - total: Total of (fake) links to generate. Defaults to 3. Not used if `links`
    is specified.
  - links: Set bounce links. Defaults to generating random (fake) data. Must be
    a list of {Server.id, Network.id, Network.ip}
  """
  def fake_bounce(opts \\ []) do
    entity_id = Keyword.get(opts, :entity_id, EntitySetup.id())
    name = Keyword.get(opts, :name, NetworkHelper.Bounce.name())
    total = Keyword.get(opts, :total, 3)
    links = Keyword.get(opts, :links, NetworkHelper.Bounce.links(total: total))

    bounce_id = Keyword.get(opts, :bounce_id, NetworkHelper.Bounce.id())

    sorted =
      bounce_id
      |> Bounce.Sorted.create(links)
      |> Changeset.apply_changes()

    entries =
      bounce_id
      |> Bounce.Entry.create(links)
      |> Enum.map(&Changeset.apply_changes/1)

    changeset =
      %Bounce{
        bounce_id: bounce_id,
        name: name,
        entity_id: entity_id,
        sorted: sorted
      } |> Changeset.change()

    bounce =
      changeset
      |> Changeset.apply_changes()
      |> Bounce.format()

    related =
      %{
        changeset: changeset,
        entries: entries,
        sorted: sorted
      }

    {bounce, related}
  end
end
