defmodule Helix.Software.Henforcer.File do

  defmodule Cracker do

    alias HELL.IPv4
    alias Helix.Network.Model.Network
    alias Helix.Server.Model.Server

    @spec can_bruteforce(Server.id, Network.id, IPv4.t) ::
      :ok
    def can_bruteforce(_source_id, _network_id, _target_ip) do
        # Check stuff like whether the victim is still under noob protection
        # - is IP(source_id) == target_ip? If so, no!
      :ok
    end

  end

end
