module EventSystem
  module Model
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      @@triggering_methods = []
      @@killing_methods = []
      @@has_add_method = false
      def creates_event(options = {}, &block)
        options.reverse_merge! :on => :create, :kind => "#{self.to_s.underscore}_event", :keep_alive => false, :destroy_on => 'before_destroy'
        class << self
          attr_accessor :callback_procs
        end
        @callback_procs ||= {}

        kind = options[:kind]
        [options[:on]].flatten.collect{|m| [:create, :save].include?(m) ? "after_#{m}".to_sym : m}.each do |method|
        
          ((callback_procs[method] ||= {})[kind] ||= []) << block
          
          # the following is necessary if the method (to be hooked) isn't already defined
          # (mostly the case, because "creates_event" will be called at the beginning of the model)
          
          @destroy_method = options[:destroy_on]
          @should_be_killed = !options[:keep_alive]
          
          unless (methods + instance_methods).include?(method.to_s)
            def method_added method_name
              if @@killing_methods.include?(method_name)
                @@killing_methods.delete(method_name)
                destroy_chain_for @destroy_method if @should_be_killed && !(methods+instance_methods).include?("#{@destroy_method}_with_indicator_kill")
              end
              if @@triggering_methods.include? method_name
	  	@@triggering_methods.delete(method_name)
		create_chain_for method_name unless (methods+instance_methods).include? "#{method_name}_with_create_events"
              end
            end
	    @@triggering_methods << method
          else
            create_chain_for method unless (methods+instance_methods).include? "#{method}_with_create_events"
	  end
        
          #
          #same again for deletion
          #
          unless (methods + instance_methods).include?(@destroy_method.to_s)
            def method_added method_name
              if @@killing_methods.include?(method_name)
                @@killing_methods.delete(method_name)
                destroy_chain_for @destroy_method if @should_be_killed && !(methods+instance_methods).include?("#{@destroy_method}_with_indicator_kill")
              end
              if @@triggering_methods.include? method_name
	  	@@triggering_methods.delete(method_name)
		create_chain_for method_name unless (methods+instance_methods).include? "#{method_name}_with_create_events"
              end
            end
            @@killing_methods << @destroy_method
          else
            destroy_chain_for @destroy_method unless options[:keep_alive] || (methods+instance_methods).include?("#{@destroy_method}_with_indicator_kill")
          end

        end
      end

      private
      #indicator creation hook
      def create_chain_for method_name
        old_method = append_to(method_name, 'without_create_events')
        define_method(append_to(method_name, 'with_create_events')) do |*args|
          self.class.callback_procs[method_name].each do |kind, blocks|
            blocks.each {|block| EventSystem::Indicator.create_from(self, kind, block)}
          end
          send(old_method, *args)
        end
        alias_method_chain method_name, :create_events
      end

      #indicator deletion hook
      def destroy_chain_for method_name
        old_method = append_to(method_name, 'without_indicator_kill')
        define_method(append_to(method_name, 'with_indicator_kill')) do |*args|
          EventSystem::Indicator.delete_all(:ref_class => self.class.to_s, :ref_id => self.id) #delete should be ok here, since indicator isn't bound to anything
          send(old_method, *args)
        end
        alias_method_chain method_name, :indicator_kill
      end


      #boring query/bang shit details follow...
      def suffix_for method
        (["!", "?"].include?(last=method.to_s[-1,2])) ? last : ""
      end

      def append_to method, tail
        suffix = suffix_for method
        "#{suffix.empty? ? method : method.to_s.chop}_#{tail}"+suffix
      end

    end
  end
end

