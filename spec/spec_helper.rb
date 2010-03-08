begin
  # we are inside a real rails application
  require File.dirname(__FILE__) + '/../../../../spec/spec_helper'
rescue LoadError
  # we are on our own
  require 'rails_generator'
  require 'rails_generator/scripts/generate'
  require 'active_record'
  require 'action_controller'
  require 'action_controller/test_process'


  require File.dirname(__FILE__) + '/assets/vanilla_app/config/boot'
  require File.dirname(__FILE__) + '/assets/vanilla_app/app/models/message.rb'
  require File.dirname(__FILE__) + '/assets/vanilla_app/app/models/user.rb'
  require File.dirname(__FILE__) + '/assets/vanilla_app/app/controllers/application_controller'
  require File.dirname(__FILE__) + '/assets/vanilla_app/app/controllers/messages_controller'

  require File.dirname(__FILE__) + '/assets/vanilla_app/config/routes'
  require File.dirname(__FILE__) + '/assets/vanilla_app/vendor/plugins/jrails/lib/jrails'

  require 'spec/rails'
  require 'event_system'
  
  require File.dirname(__FILE__) + '/../app/models/event_system/indicator.rb'
  require File.dirname(__FILE__) + '/../app/models/event_system/indicator_sequence.rb'
  Rails::Generator::Base.append_sources Rails::Generator::PathSource.new(:event_system, File.dirname(__FILE__) + '/../generators/')
  
  ActionController::Base.class_eval do
    append_view_path File.dirname(__FILE__)  + '/assets/vanilla_app/app/views'
    append_view_path File.dirname(__FILE__)  + '/../app/views'
  end
end

# set up in-memory db
unless ActiveRecord::Base.connected?
  config = YAML::load(IO.read(File.dirname(__FILE__) + "/assets/vanilla_app/config/database.yml"))
  ActiveRecord::Base.establish_connection(config["test"])
  load(File.dirname(__FILE__) + "/assets/vanilla_app/db/schema.rb")
end

# Helper functions
def reload(options)
  Object.send(:remove_const, options[:class].to_s)
  load options[:from]
end

#######################################################################################################

String.class_eval do
  define_method(:c_emp) {"\x1b\x5b\x33\x32m"}
  define_method(:c_err) {"\x1b\x5b\x33\x31m"}
  define_method(:c_rst) {"\x1b\x5bm\x0f"}
  def u2emp
    gsub(/_(.*?)_/, c_emp+'\1'+c_rst)
  end

  def u2err
    gsub(/_(.*?)_/, c_err+'\1'+c_rst)
  end

  #cap2emp
  def c2emp
    gsub(/([:A-Z:]+)/, c_emp+'\1'+c_rst).downcase
  end

  def c2err
    gsub(/([:A-Z:]+)/, c_err+'\1'+c_rst).downcase
  end
end

def random_string length=15
  (1..length).inject(""){|m, o| m += ((rand 2) == 1)? rand_upper : rand_lower}
end

def clean_fake_files
  #puts "cleaning #{@fake_files.inspect}"
  ($_fake_files ||= []).map{|ff|File.delete(ff.path)}
end

def fake_partial_file
  fake_file '/assets/vanilla_app/app/views/_', '.erb'
end

def fake_file init='/', partial=''
  path = File.dirname(__FILE__)+init+'tmp_file_'+random_string(30)+partial
  f = File.open(path, 'w+')
  f.instance_variable_set(:@rel_path, (partial.empty? ? init : init.chop)+File.basename(f.path))
  f.instance_variable_set(:@tpl_path, '/'+File.basename(f.path).last(-1).first(-4))
  File.class_eval { attr_accessor :rel_path, :tpl_path }
  (($_fake_files ||= []) << f).last
end

def rand_upper
  (0x41+rand(26)).chr
end

def rand_lower
  rand_upper.downcase!
end

def random_string length=15
  (1..length).inject(""){|m, o| m += ((rand 2) == 1)? rand_upper : rand_lower}
end

def model_mocks klass, array, attribute
  array.inject([]){|m, o| m << (mock_model(klass, attribute => o))}
end

def habtm_table_name name0, name1
  n0 = name0.to_s.pluralize.underscore
  n1 = name1.to_s.pluralize.underscore
  (n0 < n1) ? "#{n0}_#{n1}" : "#{n1}_#{n0}"
end