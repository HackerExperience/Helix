defprotocol Helix.Event.Notificable do

  def get_notification_data(event)

  def whom_to_notify(event)

  def extra_params(event)

end
