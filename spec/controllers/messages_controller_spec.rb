require File.dirname(__FILE__) + '/../spec_helper'

ESI = EventSystem::Indicator
SEQ = EventSystem::IndicatorSequence

describe MessagesController, 'plugin integration', :type => :controller do
  integrate_views
  
  before :all do
    # @message = mock_model Message
    # @indicator = mock_model EventSystem::Indicator
    #ESI.stub!(:all).and_return(@event = mock_model(ESI, :save=>true))
  end

  after :all do
    clean_fake_files
  end
  
  before :each do
    reload :class => MessagesController,
           :from  => File.dirname(__FILE__) + '/../assets/vanilla_app/app/controllers/messages_controller.rb'
  end
  
  # INITIAL TESTS
  #describe 'Controller-Test-System-Prerequisits' do
  #before :each do
  #  reload :class => MessagesController, :from => '/app/controllers/messages_controller.rb'
  #end
  it "should respond to the index method/action" do
    controller.class.class_eval do
      define_method(:damn_test_func) do
        #puts "damn test func"
        render :text => 'damn test func'
      end
    end
    get :damn_test_func
    response.should be_success
    get :index
    response.should be_success
    #puts "[#{response.body}]"
  end

  it "should not have the updates_for_index method defined" do
    controller.respond_to?(:updates_for_index).should be_false
  end

  it "should have the update_for_index method defined after plugging in the event system" do
    MessagesController.class_eval do
      handles :message, :index, :with => proc{ puts "Hallo Welt" }
    end
    @controller = MessagesController.new
    
    controller.respond_to?(:updates_for_index).should be_true
  end
  #end
  
  ### SECTION : SELECT / REJECT
  
  #describe 'the Controllers selecting/rejecting behaviour' do
  it "should NOT call the custom function if there are no Indicators" do
    ESI.delete_all
    controller.class.class_eval do
      handles :message, :index,  :with => proc{ puts 'proc message index called' }
      handles :score,   :show, :with => :my_func
    end
    @controller = MessagesController.new
    
    controller.should_not_receive(:my_func)
    get :updates_for_show
    #get :index
    #puts controller.object_id
    #puts "index body [#{response.body}]"
  end

  it "should NOT call the custom function if there are no Indicators for the specified class" do
    ESI.delete_all
    controller.class.class_eval do
      handles :message, :index,  :with => proc{ puts 'proc message index called' }
      handles :score,   :show, :with => :my_func
    end
    @controller = MessagesController.new
    4.times do |n|
      ESI.create(:ref_class => 'Message', :ref_id => n)
    end
    controller.should_not_receive(:my_func)
    get :updates_for_show
  end

  it "should call the custom function for each Indicator" do
    ESI.stub!(:find).and_return([mock_model(ESI)].cycle(5).to_a)
    expected_string = random_string 20

    MessagesController.class_eval do
      handles :message, :index,  :with => proc{ puts 'proc message index called' }
      handles :score,  :show, :with => :my_func

      define_method(:my_func) {expected_string}
    end
    
    @controller = MessagesController.new

    get :updates_for_show, :last_load => 1 #load is ignored here
    response.body.should include(expected_string.cycle(5).to_a.join)
    
    #controller.updates_for_show
  end
  #end

  ### SECTION: OPTION COMBINATIONS AND MULTIPLE 'handles' calls
  #describe 'option combinations ' do
  it "should call every function entry for each Indicator-class" do
    fake_tpl = fake_partial_file
    tpl_content = random_string(20)+"\n"
    fake_tpl << tpl_content
    fake_tpl.close

    MessagesController.class_eval do
      handles :message, :index,  :with => proc{|ind|ind.ref_class}
      handles :score, :show, :with => :my_func, :template => fake_tpl.tpl_path
      #handles :score, :index, :with => :my_func
    end
    
    MessagesController.class_eval do
      define_method(:my_func) {|ind|ind}
    end
    @controller = MessagesController.new
    ESI.stub!(:find).and_return([mock_model(ESI)].cycle(5).to_a)
    get :updates_for_show, :last_load => 1 #load is ignored here
    response.body.should include(tpl_content * 5)

    ESI.stub!(:find).and_return([mock_model(ESI, :ref_class => 'Message')].cycle(8).to_a)
    get :updates_for_index, :last_load => 1 #load is ignored here
    response.body.should include('Message'.cycle(8).to_a.join)
  end

  #THIS TEST IS THE FAT ONE. TESTS MANY ASPECTS
  it "should handle all indicated objects within the same (update-)action" do
    MessagesController.class_eval do
      handles :message, :index,  :with => proc{|ind|ind.ref_id.to_s}
      handles :score, :index, :with => proc{|ind|ind.ref_class}
    end
    @controller = MessagesController.new
    ESI.delete_all
    SEQ.set(seq = 4)
    7.times do |n|
      ESI.create_from(mock_model(Message, :id => n))
    end
    5.times do |n|
      ESI.create_from(mock('Score', :id => n, :class => 'Score'))
    end

    #we skip 2 events
    get :updates_for_index, :last_load => seq+2
    response.should have_text(Regexp.new('23456' + 'Score'*5+'|'+'Score'*5 + '23456'))
  end
  #end

  it 'should render the fallback updater if no tpl has been found' do
    ESI.stub!(:find).and_return([mock_model(ESI)].cycle(5).to_a)

    MessagesController.class_eval do
      handles :message, :tpl_missing, :with => proc{ |ind| Message.new()}

      define_method(:tpl_missing) {render :text => "tpl missing action rendered(shouldn't be displayed)"}
    end
    @controller = MessagesController.new

    get :updates_for_tpl_missing, :last_load => 1
    #puts "ANSWER:#{response.body}"
    response.body.should include('jQuery(')
    response.body.should include('')

  end

  ### SECTION: EVENT NUMBER
  #describe 'event number handling ' do
  it 'should set the current_event_number' do
    # the usual bullshit, man let's eval this
    SEQ.set 100125
    MessagesController.class_eval do
      handles :message, :index,  :with => proc{ |ind| "some text"}
    end
    @controller = MessagesController.new
    # bullshit ends here , pheew, hard work ;)
    #finally some expectations?
    ESI.create(:ref_class => 'Message', :ref_id => 5)
    get :updates_for_index, :last_load => 5
    
    #puts response.body
    #@controller.current_event_number.should == 5
    #response.should have_tag('span')
    response.body.should include('100125')

  end
  
  #end

  it 'should be an EXCEPTION raised in the following test'.c2err
  
  it '_SHOULD_ be an _ERROR_ by _EXCEPTION_. YOU SEE THIS? OK, THEN YOU GOT IT!!!'.u2err do
    #this is the old double class instance behaviour
    #the reload doesn't clears the damn test func...
    #from the test below, it is NOT called, but there is no exception
    get :damn_test_func
  end

end

