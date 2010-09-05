class CreateEventSystem < ActiveRecord::Migration
  def self.up
    create_table :event_system_indicators do |t|
      t.integer :ref_id
      t.string  :ref_class
      t.string  :attachment
      t.string  :kind
      t.decimal :number, :precision => 20, :scale => 0
      t.timestamps
    end
    add_index :event_system_indicators, [:number, :ref_class, :ref_id]
    
    create_table :event_system_indicator_sequence, :force => true do |t|
      t.decimal :number, :precision => 20, :scale => 0
    end
    EventSystem::IndicatorSequence.create(:number => 1)
    
  end

  def self.down
    drop_table :event_system_indicators
    drop_table :event_system_indicator_sequence
  end
end
