defprotocol Helix.Process.Model.Process.SoftwareType do

  @type resource :: :cpu | :ram | :dlk | :ulk

  @spec dynamic_resources(t) :: [resource]
  def dynamic_resources(data)

  def event_namespace(data)
end