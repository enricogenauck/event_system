require File.dirname(__FILE__) + '/../spec_helper'

describe EventSystem::Helper, :type => :helper do
  before :all do
  end
  
  it "should integrate_event_system for an updatable action" do
    helper.should_receive(:action_name).twice.and_return("index")
    helper.should_receive(:controller_name).and_return("messages")
    
    returning(helper.instance_variable_get(:@controller)) do |c|
      MessagesController.stub!(:method_defined?).and_return(true)
      c.should_receive(:class).and_return(MessagesController)
      c.should_receive(:event_system_update_interval).and_return(5)
    end

    html = helper.integrate_event_system
    html.should have_tag("script")
    html.should include("updates_for_index")
    html.should include("setInterval(function() {getNewEvents('/messages/updates_for_index');}, 5000);")
    html.should include("?last_load=")
  end
  
  it "should not integrate_event_system for an unupdatable action" do
    helper.should_receive(:action_name).once.and_return("index")
    helper.instance_variable_get(:@controller).class.should_receive(:method_defined?).with("updates_for_index").and_return(false)
    
    html = helper.integrate_event_system
    html.should be_empty
  end

  it "should set the current_event_number" do
    helper.should_receive(:action_name).twice.and_return("index") #why twice?
    
    ctrl = helper.instance_variable_get(:@controller)
    ctrl.class.should_receive(:method_defined?).with("updates_for_index").and_return(true)
    EventSystem::IndicatorSequence.should_receive(:current).and_return(5779)
    #ctrl.instance_variable_set(:@current_event_number,5779)
    html = helper.integrate_event_system
    html.should include('5779')
  end
end