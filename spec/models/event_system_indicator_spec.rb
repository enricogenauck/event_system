require File.dirname(__FILE__) + '/../spec_helper'

describe EventSystem::Indicator do 
  describe EventSystem::IndicatorSequence do
    it 'should increment the sequence value' do
      EventSystem::IndicatorSequence.count.should == 1
      @counter = EventSystem::IndicatorSequence.next!
      EventSystem::IndicatorSequence.next!.should eql(@counter.succ)
    end
  end
end

