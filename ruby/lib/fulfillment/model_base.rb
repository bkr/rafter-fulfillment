module Fulfillment
  class ModelBase

    protected

    def make_getter_methods(data_hash)
      eigenclass = class << self; self; end

      data_hash.each do |key, value|
        instance_variable_set "@#{key}", value
         eigenclass.send(:define_method, key) do
            instance_variable_get "@#{key}"
          end
      end
    end

    def make_setter_methods(data_hash)
      eigenclass = class << self; self; end

      data_hash.each do |key, value|
        eigenclass.send(:define_method, "@#{key}=") do |new_value|
          instance_variable_set "@#{k}", new_value
        end
      end
    end
  end
end