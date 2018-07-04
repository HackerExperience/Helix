defmodule Helix.ID do
  @moduledoc """
  `Helix.ID` is the internal ID format used by Helix.

  It is designed to enhance spatial and temporal locality at the data storage
  level, while being collision-safe and relatively small in size (128 bits).

  At the data storage level we use INET, so our resulting ID is actually an IPv6
  address, which is made of 8 groups of 4 hexadecimal characters each, totaling
  128 bits.

  ## Format breakdown

  The 128 bits are split into 5 sections, in that order (left to right):

  - 24 bits used to identify the object's grandparent (if any).
  - 30 bits used to identify the object's parent (if any).
  - 30 bits used to mark the exact second that the object was created.
  - 36 bits of random digits used as the object identifier.
  - 8 bits of metadata/domain information, flagging what the object represents.

  In an IPv6-like format, total bits in parenthesis, 16 bits per group, we have:

  g(16):g(8)p(8):p(16):p(6)t(10):t(16):t(4)o(12):o(16):o(8)d(8)

  And here's a more readable approximation (not 100% accurate!):

  gggg:ggpp:pppp:pttt:tttt:tooo:oooo:oodd

  ## Data locality

  Data locality, both spatial and temporal, enables the database layer to more
  efficiently cache game data, as it is likely that related data will be stored
  on contiguous, or at the same, filesystem block(s).

  ### Temporal locality

  Temporal locality groups all entries by insertion time. We achieve that by
  reserving 30 bits to a timestamp hash.

  30 bits have a total of 1_073_741_824 possibilities, and if you increment a
  counter once every second, it will reach 2^30 in ~34 years. This is a good
  compromise that we've took, so our timestamp hashing algorithm basically
  counts how many seconds have passed since `helix_epoch`.

  This means Helix IDs will be "valid" for 34 years, until ~2052. When (if) that
  time comes, the hash will restart from 0.

  ### Spatial locality

  Spatial locality groups together data owned by the same user / object, thus
  enhancing filesystem-level cache.

  We achieve that by reserving 54 bits used to identify which IDs originated the
  current one.

  These 54 bits are further split into two parts, a 24-bit one used to identify
  the object's grandparent, and a 30-bit one used to identify the object's
  parent. An object may have no parent, only one parent, or a parent and a
  grandparent.

  Here's an interesting example. Imagine a Process. That Process belongs to a
  Server. That Server belongs to an Entity. That Entity belongs to no one.

  #### No parent

  The Entity ID does not have neither grandparent or parent. In this case, the
  54 reserved bits are generated randomly.

  #### Parent

  The Server ID only has one parent, the Entity ID. In this case, all 54
  heritage bits will be used to store a hash of the parent ID.

  This hash will fetch 19 bits from the Entity ID's grandparent, 19 bits from
  the Entity ID's parent and 16 bits from the Entity ID's object.

  #### Grandparent and parent

  The Process ID has Server ID as a parent, and Entity ID as a grandparent. In
  this scenario, 24 bits will be used for the grandparent (Entity) and 30 bits
  for the parent (Server).

  The grandparent hash will fetch 10 bits from the Entity grandparent, 10 bits
  from the Entity parent, and 4 bits from the Entity object.

  The parent hash will fetch 11 bits from the Server's grandparent, 11 bits from
  the Server's parent, and 8 bits from the Server's object.

  ## Thoughts on collision safety

  As seen on `Temporal locality` section, the timestamp hash is incremented
  every second. This means that if a collision were to happen, it must happen
  within the same second. Once the timestamp hash changes, it's impossible that
  previous hashes could collide with new ones (unless it's 2052 and the
  timestamp algorithm started over).

  On top of that, there are 36 bits guaranteed to be pseudo-random - the
  `object` bits. That brings ~70 billions combinations at the table. A rough
  approximation of the birthday paradox gives a 1% collision chance once we have
  ~40k entries.

  This is not enough, one might wonder. And, by itself, it isn't. But remember,
  that's 1% chance of collision if we insert 40k entries at the same second!

  There are 8 special bits used to flag which domain that ID has, potentially
  with metadata. For instance, all user entities end with 0x0A, while all NPC
  entities end with 0x1A. This means that those 40k entries must happen within
  the same domain, e.g. 40k *log* entries generated in one second.

  Since we will never be anywhere near Facebook scale, that's already good
  enough. But we still have 54 bits to use!

  The remaining 54 bits are used to give spatial locality to the ID, and they
  indicate from which object that ID came from (see `Spatial locality` for more
  details). Meaning that, using the same example above, in order to have a 1%
  chance of collision, we'd need 40k log entries *on the same server* generated
  in one second.

  I'm not a mathematician but that seems good enough. Q.E.D.

  ## Bonus: human-friendly

  As a bonus (but an intentional one), our IDs are human-friendly, meaning that
  a well trained human being will know which object an ID represents just by
  looking at it.

  You see (pun intended), the last 8 bits (2 hexadecimal characters) are used to
  identify the object represented by the ID. For instance, all log IDs end with
  `09` characters.

  In some cases we even add some metadata information to the ID, usually to
  specify the type of the object. For instance, all download processes end with
  `03`, but all upload processes end with `13`. Bruteforce processes end with
  `23`.

  We follow a little-endian-like format for the domain representation, i.e. the
  least significant *byte* represents the macro domain (process), and the most
  significant *byte* represents the object metadata (download/upload).

  This information could prove extremely valuable during a debug section!

  ## Reminder: Keep your data together

  While out of scope, here's an important reminder: Postgres does not sort new
  rows physically. This means that even though the logical data is sorted, it
  isn't physically sorted, reducing the locality benefits.

  One should use the `CLUSTER` command. Beware, though, that `CLUSTER` only
  works for existing data; any data that is inserted after the command will be
  out of order. Also keep in mind that `CLUSTER` will lock the table with an
  `ACCESS EXCLUSIVE` lock.

  The ideal case here is to use `pg_repack` on a periodic fashion. `pg_repack`
  implements a mostly asynchronous version of `CLUSTER` (with a couple
  operations that will lock the table, but are quite fast). Add it to a cron job
  during a low-usage period and you are good to go. Data inserted during the day
  will be physically unsorted but it is likely that they will be on the cache
  anyway. Tuning the table's `fillfactor` accordingly should help too.
  """

  import HELL.Macros

  alias __MODULE__

  @type heritage ::
    %{grandparent: id, parent: id}
    | %{parent: id}
    | %{}

  @type id :: map | tuple
  @type parsed_id :: ID.Utils.parsed_id

  @doc """
  The `helix_epoch` is the starting time for Helix, after which each second will
  change the resulting hash.

  The epoch is July 1st, 2018 00:13:37 AM UTC.
  """
  @helix_epoch 1_530_404_017
  @modulo_time ID.Utils.modulo_for(30)

  @spec generate(heritage, ID.Domain.domain) ::
    tuple
  def generate(heritage, domain) do
    {gp, p} = hash_heritage(heritage)
    t = hash_time()
    o = ID.Utils.random_bits(36)
    d = ID.Domain.get_domain(domain)

    gp <> p <> t <> o <> d
    |> ID.Utils.bin_to_id()
  end

  def hash_time do
    d = DateTime.utc_now()
    unix_ts = DateTime.to_unix(d)

    diff = unix_ts - @helix_epoch

    mod = rem(diff, @modulo_time)

    mod
    |> Integer.to_string(2)
    |> String.pad_leading(30, "0")
  end

  @spec hash_heritage(heritage) ::
    {grandparent_hash :: binary, parent_hash :: binary}
  @doc """
  Based on the `heritage` map, generates the heritage hash.

  If `heritage` is an empty map, 54 random bits will be generated.
  If only a `parent` is specified, a 54-bit hash will be generated from the
  given `parent`.
  If both `parent` and `grandparent` are given, a 24-bit hash is generated from
  the `grandparent`, and a 30-bit one from the `parent`.
  """
  def hash_heritage(%{grandparent: grandparent, parent: parent}),
    do: {hash_id(grandparent, 10, 10, 4), hash_id(parent, 11, 11, 8)}

  def hash_heritage(%{parent: parent}) do
    heritage_bin = hash_id(parent, 19, 19, 16)

    {String.slice(heritage_bin, 0..23), String.slice(heritage_bin, 24..53)}
  end

  def hash_heritage(heritage) when map_size(heritage) == 0,
    do: {ID.Utils.random_bits(24), ID.Utils.random_bits(30)}

  @spec hash_id(map | tuple, pos_integer, pos_integer, pos_integer) ::
    binary
  docp """
  Generates a heritage hash from `id`, with `bits_gp`, `bits_p` and `bits_o` the
  total bits that should be retrieved from each section.

  Notice that the resulting hash does not depend on the `id`'s timestamp and
  domain; they are ignored.
  """
  defp hash_id(id, bits_gp, bits_p, bits_o) do
    data = parse(id)

    modulo_gp = ID.Utils.modulo_for(bits_gp)
    modulo_p = ID.Utils.modulo_for(bits_p)
    modulo_o = ID.Utils.modulo_for(bits_o)

    gp = rem(data.grandparent.dec, modulo_gp)
    p = rem(data.parent.dec, modulo_p)
    o = rem(data.object.dec, modulo_o)

    gp_bin = Integer.to_string(gp, 2) |> String.pad_leading(bits_gp, "0")
    p_bin = Integer.to_string(p, 2) |> String.pad_leading(bits_p, "0")
    o_bin = Integer.to_string(o, 2) |> String.pad_leading(bits_o, "0")

    gp_bin <> p_bin <> o_bin
  end

  @doc """
  Parses an Helix ID.
  """
  defdelegate parse(id),
    to: ID.Utils
end
