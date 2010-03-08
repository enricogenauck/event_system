class EventSystemGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      m.migration_template  'migrate/create_event_system.rb', 'db/migrate'
    end
  end
  
  def file_name
    "create_event_system"
  end
end