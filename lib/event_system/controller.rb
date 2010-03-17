module EventSystem
  DEFAULT_PARTIAL_PATH = '%s/updates_for_%s'
  FALLBACK_UPDATE_PARTIAL = 'default/updates'
  UPDATE_SEQUENCE_PARTIAL = '/set_last_load_number'
  UPDATE_INTERVAL = 5

  module Controller
    def self.included(base)
      base.send(:include, InstanceMethods)
      base.extend(ClassMethods)
    end

    module ClassMethods
      attr_accessor :event_handlers
      
      def handles(klass, action, options = {})
        @event_handlers ||= {}
        options.reverse_merge! :with => proc{|ind| ind.reference}
        options[:template] ||= format DEFAULT_PARTIAL_PATH, klass.to_s.underscore.pluralize, action
        (@event_handlers[action.to_sym] ||= {}).merge!(
          klass.to_sym => [options[:with], options[:template]]
        )
        define_method("updates_for_#{action.to_s}") { process_events(action) }

        ActionController::Routing::Routes.draw do |map|
          map.connect "/#{controller_name}/updates_for_#{action.to_s}",
                      :controller => controller_name,
                      :action     => "updates_for_#{action.to_s}"
        end

        # BAD HACK AGAIN
        # this ensures that we are at the beginning of the route list
        ActionController::Routing::Routes.routes = 
          [ActionController::Routing::Routes.routes.pop]+ActionController::Routing::Routes.routes
        
      end
    end

    module InstanceMethods
      attr_accessor :current_event_number
      
      def process_events(action)
        (render :nothing => true;return) if (last_load = params[:last_load].to_i) == 0
        update_response = ''

        self.class.event_handlers[action].each do |klass, arr|
          handler = arr[0].instance_of?(Symbol) ? proc{|arg|send(arr[0], arg)} : arr[0]
          tpl = arr[1]

          #HACK solution
          #TODO: find a proper solution to get this code readable

          2.times do |n|
            begin
              update_response += render_to_string(
                :partial => tpl,
                :collection => Indicator.find(:all,
                  :conditions => ["ref_class = ? AND number > ?", klass.to_s.camelize, last_load]
                ).map {|ind| handler.call(ind)},
                :as => :object
              )
              break
            rescue ActionView::MissingTemplate
              tpl = FALLBACK_UPDATE_PARTIAL
            end
          end

        end

        if update_response.empty?
          render :nothing => true
        else
          update_response += render_to_string(
            :partial => UPDATE_SEQUENCE_PARTIAL, :locals => {:load_number => EventSystem::IndicatorSequence.current}
          )
          render :text => update_response
        end
      end
    end

    def event_system_update_interval
      UPDATE_INTERVAL
    end
  end
  #module Routes
  #  def draw(map)
  #end
end

