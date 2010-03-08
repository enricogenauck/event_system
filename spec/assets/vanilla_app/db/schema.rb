ActiveRecord::Schema.define(:version => 1) do
 
  create_table :messages, :force => true do |t|
    t.integer :user_id
  end
  
  create_table :users, :force => true do |t|
  end

  create_table :event_system_indicators, :force => true do |t|
    t.integer :ref_id
    t.string  :ref_class
    t.string  :attachment
    t.string  :kind
    t.decimal :number, :precision => 20, :scale => 0
  end

  create_table 'event_system_indicator_sequence', :force => true do |t|
    t.decimal :number, :precision => 20, :scale => 0
  end
  EventSystem::IndicatorSequence.create(:number => 0)
 
end
