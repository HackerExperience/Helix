defprotocol Helix.Process.Model.Process.SoftwareType do

  def allocation_handler(data)
  def flow_handler(data)
  def event_namespace(data)
end