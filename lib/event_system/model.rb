module EventSystem
  module Model
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      attr_accessor :callback_procs

      def creates_event(options = {}, &block)
        options.reverse_merge! :on => [:create], :kind => "#{self.to_s.underscore}_event"
        kind = options[:kind]
        [options[:on]].flatten.each do |method|
          if [:create, :save].include?(method)
            self.send("after_#{method}", proc{ |obj| EventSystem::Indicator.create_from(obj, kind, block) })
          else
            define_method("#{method}_with_create_event") do |*args|
              EventSystem::Indicator.create_from(self, kind, block)
              if (args.nil? || args.empty?)
                self.send("#{method}_without_create_event")
              else
                self.send("#{method}_without_create_event", args)
              end
            end
            self.send(:alias_method_chain, method, :create_event)
          end
        end

      end
    end
  end
end
