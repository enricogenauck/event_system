EVENT_SYSTEM_PATH = File.dirname(__FILE__) + "/event_system/"

%w(controller model helper).each do |library|
  require EVENT_SYSTEM_PATH + library
end

ActionController::Base.send :include, EventSystem::Controller
ActiveRecord::Base.send     :include, EventSystem::Model
ActionView::Base.send       :include, EventSystem::Helper