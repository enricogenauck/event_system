class EventSystem::Indicator < ActiveRecord::Base
  attr_accessible :ref_id, :ref_class, :ref_data, :kind, :number
  set_table_name :event_system_indicators

  def self.create_from(obj = nil, kind = nil, block = nil)
    indicator = new(:ref_id     => obj ? obj.id : nil,
                    :ref_class  => obj ? obj.class.to_s : nil,
                    :kind => kind.to_s,
                    :number => EventSystem::IndicatorSequence.next!)
    if block
      block.call(indicator)      if block.arity == 1
      block.call(indicator, obj) if block.arity == 2
    end
    indicator.save
  end

  def attachment(data = nil)
    if data
      self[:attachment] = Marshal.dump(data)
    else
      Marshal.load(self[:attachment]) if self[:attachment]
    end
  end
  
  def reference(object = nil)
    if object
      self.ref_id = object.id
      self.ref_class = object.class.to_s
    else
      ref_class.constantize.find(ref_id)
    end
  end
  
  def kind
    self[:kind].to_sym
  end
end

