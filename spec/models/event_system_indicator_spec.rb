require File.dirname(__FILE__) + '/../spec_helper'

describe EventSystem::Indicator do
  describe "initial class expansion" do
    describe :creation do
      before :each do
        EventSystem::Indicator.destroy_all
        reload :class => Message,
               :from  => File.dirname(__FILE__) + '/../assets/vanilla_app/app/models/message.rb'
      end
      
      it "should be created when a new message is created if theres an entry in it's class definition" do
        Message.class_eval{creates_event :kind => :message_event, :on  => [:create]}
        Message.create()
        EventSystem::Indicator.should have(1).records
      end

      it "should be created and return the method's value" do
        Message.class_eval{creates_event :kind => :message_event, :on  => [:process]}
        @message = Message.create()
        @message.process.should eql("Message is being processed")
        EventSystem::Indicator.should have(1).records
      end

      it "should set the event kind" do
        Message.class_eval{creates_event :kind => :message_event, :on => :create}
        Message.create()
        EventSystem::Indicator.first.kind.should eql(:message_event)
      end
      
      it "should be created three times with custom properties" do
        Message.class_eval{
          creates_event :kind => :message_event
          creates_event :kind => :phantasy_event
          creates_event :kind => :process_event, :on => :process do |event|
            event.attachment "custom event triggered"
          end
        }
        @message = Message.create()
        @message.process()
        EventSystem::Indicator.should have(3).records
        EventSystem::Indicator.all[0].kind.should eql(:message_event)
        EventSystem::Indicator.all[1].kind.should eql(:phantasy_event)
        EventSystem::Indicator.all[2].kind.should eql(:process_event)
        EventSystem::Indicator.all[2].attachment.should eql("custom event triggered")

      end
      
      it "should be created with custom data accessor as string using inline block" do
        Message.class_eval{
          creates_event(:kind => :message_event, :on => :create) { |event| event.attachment "custom_message" }
        }
        Message.create()
        EventSystem::Indicator.first.attachment.should eql("custom_message")
      end
      
      it "should be created with custom data accessor as array" do
        Message.class_eval{
          creates_event :kind => :message_event, :on  => :create do |event|
            event.attachment [1,2,3]
          end          
        }
        Message.create()
        EventSystem::Indicator.first.attachment.should eql([1,2,3])
      end
      
      it "should be created with custom data accessor as method return value" do
        Message.class_eval{
          creates_event :kind => :message_event, :on  => :create do |event|
            event.attachment [1,2,3].first
          end
        }
        Message.create()
        EventSystem::Indicator.first.attachment.should eql(1)
      end

      it "should be created with custom reference object" do
        Message.class_eval{
          creates_event :kind =>  :message_event, :on  => :create do |event, message|
            event.reference  message.user
            event.attachment [1,2,3].first
          end
        }
        @user = User.create()
        Message.create(:user => @user)
        EventSystem::Indicator.first.reference.should eql(@user)
      end
      
      it "should create the default event with incomplete definition" do
        Message.class_eval{creates_event}
        Message.create()
        EventSystem::Indicator.should have(1).records
        EventSystem::Indicator.first.kind.should eql(:message_event)
      end

      it "should expose the object accessor" do
        Message.class_eval{creates_event :kind => :message_event, :on => :create}
        @message = Message.create()
        EventSystem::Indicator.first.reference.should eql(@message)
      end
      
      it "should have ascending sequence number" do
        Message.class_eval{creates_event}
        Message.create()
        EventSystem::Indicator.should have(1).record
        @counter = EventSystem::Indicator.first.number
        Message.create()
        EventSystem::Indicator.should have(2).records
        EventSystem::Indicator.all.collect{|i| i.number}.sort.should eql([@counter,@counter.succ])
      end
    end
  end
  
  describe EventSystem::IndicatorSequence do
    it 'should increment the sequence value' do
      EventSystem::IndicatorSequence.count.should == 1
      @counter = EventSystem::IndicatorSequence.next!
      EventSystem::IndicatorSequence.next!.should eql(@counter.succ)
    end
  end
  
end
