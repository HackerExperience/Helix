alias Helix.Network.Repo
alias Helix.Network.Model.Network

internet = %Network{network_id: "::", name: "Internet"}
Repo.insert!(internet, on_conflict: :nothing)
