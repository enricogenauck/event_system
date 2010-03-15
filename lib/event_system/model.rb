module EventSystem
  module Model
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      attr_accessor :callback_procs
      @@triggering_methods = []
      def creates_event(options = {}, &block)
        options.reverse_merge! :on => [:create], :kind => "#{self.to_s.underscore}_event"#, :virtual => false
        kind = options[:kind]
        [options[:on]].flatten.each do |method|
          if [:create, :save].include?(method)
            self.send("after_#{method}", proc{ |obj| EventSystem::Indicator.create_from(obj, kind, block) })
          else
            suffix=(["!", "?"].include?(last=method.to_s[-1,2])) ? last : ""
            define_method("#{suffix.empty? ? method : method.to_s.chop}_with_create_event"+suffix) do |*args|
              EventSystem::Indicator.create_from(self, kind, block)
              #if (args.nil? || args.empty?)
              #  self.send("#{method}_without_create_event")
              #else
              #  self.send("#{method}_without_create_event", args)
              #end
              send((suffix.empty? ? method.to_s : method.to_s.chop)+'_without_create_event'+suffix, *args)
            end
	    unless (methods + instance_methods).include?(method.to_s)
              def method_added method_name
              	if @@triggering_methods.include? method_name		  
	  	  @@triggering_methods.delete(method_name)
		  alias_method_chain method_name, :create_event
                end
              end
	      @@triggering_methods << method
            else
              self.send(:alias_method_chain, method, :create_event)
	    end
          end
        end
        

      end
    end
  end
end

