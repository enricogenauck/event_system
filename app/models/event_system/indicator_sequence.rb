class EventSystem::IndicatorSequence < ActiveRecord::Base
  set_table_name :event_system_indicator_sequence

  def self.current
    first.number
  end

  def self.next
    first.number.succ
  end

  def self.next!
    next_number = first.number.succ
    self.update_all(:number => next_number)
    next_number
  end

  def self.set num
    self.update_all(:number => num)
  end
end