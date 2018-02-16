defmodule Helix.Test.Network.Setup.Bounce do

  alias Ecto.Changeset
  alias Helix.Network.Internal.Bounce, as: BounceInternal
  alias Helix.Network.Model.Bounce
  alias Helix.Network.Repo, as: NetworkRepo

  alias Helix.Test.Entity.Setup, as: EntitySetup
  alias Helix.Test.Network.Helper, as: NetworkHelper

  @doc """
  See docs on `fake_bounce/1`
  """
  def bounce(opts \\ []) do
    {bounce, related = %{changeset: changeset, entries: entries}} =
      fake_bounce(opts)

    NetworkRepo.insert!(changeset)
    Enum.each(entries, &NetworkRepo.insert!/1)

    # Fetching again to ensure it's correctly formatted
    {BounceInternal.fetch(bounce.bounce_id), related}
  end

  def bounce!(opts \\ []) do
    {bounce, _} = bounce(opts)
    bounce
  end

  @doc """
  - bounce_id: Set bounce id.
  - entity_id: Set entity who owns the bounce.
  - name: Set bounce name.
  - total: Total of (fake) links to generate. Defaults to 3. Not used if `links`
    is specified.
  - links: Set bounce links. Defaults to generating random (fake) data. Must be
    a list of {Server.id, Network.id, Network.ip}
  - servers: Similar to `links`, but when the caller does not care about the
    server's NIP (fake IPs are generated).
  """
  def fake_bounce(opts \\ []) do
    entity_id = Keyword.get(opts, :entity_id, EntitySetup.id())
    name = Keyword.get(opts, :name, NetworkHelper.Bounce.name())
    total = Keyword.get(opts, :total, 3)

    links =
      cond do
        opts[:links] ->
          opts[:links]

        opts[:servers] ->
          Enum.map(
            opts[:servers], fn server_id ->
              {server_id, NetworkHelper.internet_id(), NetworkHelper.ip()}
            end
          )

        true ->
          NetworkHelper.Bounce.links(total: total)
      end

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
      }
      |> Changeset.change()

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
