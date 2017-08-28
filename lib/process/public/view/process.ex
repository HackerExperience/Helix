defprotocol Helix.Process.API.View.Process do

  # Entity and Server data are included to allow the viewable to render
  # differently for the process creator or if seen from an external server
  def render(data, process, server_id, entity_id)
end
