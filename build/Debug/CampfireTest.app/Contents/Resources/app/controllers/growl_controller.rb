class GrowlController < Rucola::RCController
  def after_init
    #@growl = Growl::Notifier.alloc.initWithDelegate(self)
    @growl = Growl::Notifier.alloc.initWithDelegate(self)
    p @growl
    
    @growl.start(:Campfire, NOTIFICATIONS, NOTIFICATIONS)
    
    growl('TITEL!', 'WAT EEN OMSCHRIJVING JOH!')
  end
  
  # NOTIFICATIONS = [{
  #   'GROWL_NOTIFICATION_NAME' => 'A new channel message was received.',
  #   'GROWL_NOTIFICATION_TITLE' => 'New channel message',
  #   'GROWL_NOTIFICATION_DESCRIPTION' => 
  # }]
  NOTIFICATION_NAME = 'Received a new channel message.'
  NOTIFICATIONS = [NOTIFICATION_NAME]
  
  def growl(title, description)
    # GrowlApplicationBridge
    #   notifyWithTitle:(NSString *)title
    #   description:(NSString *)description
    #   notificationName:(NSString *)notificationName
    #   iconData:(NSData *)iconData
    #   priority:(signed int)priority
    #   isSticky:(BOOL)isSticky
    #   clickContext:(id)clickContext
    
    # OSX::GrowlApplicationBridge.objc_send(
    #   :notifyWithTitle, title,
    #   :description, description,
    #   :notificationName, NOTIFICATION_NAME,
    #   :iconData, nil,
    #   :priority, nil,
    #   :isSticky, false,
    #   :clickContext, nil
    # )
    @growl.notify(NOTIFICATION_NAME, title, description)
  end
end