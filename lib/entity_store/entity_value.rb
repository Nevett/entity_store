module EntityStore
  module EntityValue
    def self.included(klass)
      klass.class_eval do
        extend ClassMethods
      end
    end
    
    def initialize(attr={})
      attr.each_pair { |k,v| self.send("#{k}=", v) }
    end
    
    module ClassMethods
      def define_attributes(*attrs)
        attrs.each do |a|
          define_method(a) { instance_variable_get("@#{a}")}
          define_method("#{a}=") { |value| instance_variable_set("@#{a}", value)}
        end
        define_method(:attributes) do 
          hash = {}
          attrs.each do |m| 
            value = send(m)
            hash[m] = value.respond_to?(:attributes) ? value.send(:attributes) : value
          end
          hash
        end
      end
      
      def entity_value_attribute(name, klass)
        define_method(name) { instance_variable_get("@#{name}") }
        define_method("#{name}=") do |value|
          instance_variable_set("@#{name}", value.is_a?(Hash) ? klass.new(value) : value)
        end
      end
    end
  end
end