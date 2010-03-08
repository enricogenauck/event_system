require File.dirname(__FILE__) + '/../spec_helper'

describe EventSystemGenerator do
  before :all do
    @fake_rails_root = File.join(File.dirname(__FILE__), 'rails_root')
    FileUtils.mkdir_p(@fake_rails_root)
    @original_files = Dir.glob(File.join(@fake_rails_root, "db/migrate/*"))
  end
  
  after :all do
    FileUtils.rm_r(@fake_rails_root)
  end

  describe "creates a migration for the indicator model" do
    it "should create the single essential migration" do
      Dir.glob(File.join(@fake_rails_root, "db/migrate/*")).should be_empty
      Rails::Generator::Scripts::Generate.new.run(["event_system"], :destination => @fake_rails_root)
      Dir.glob(File.join(@fake_rails_root, "db/migrate/*")).size.should eql(1)
    end  
  end
end
