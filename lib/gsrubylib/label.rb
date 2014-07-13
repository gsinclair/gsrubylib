require 'gsrubylib'

class GS
  class Label
    class << self
      private :new
    end

    def Label.create(*symbols)
      validate_args(symbols)
      label_class(symbols)
    end

    private

    def Label.validate_args(symbols)
      if symbols.empty?
        fail ArgumentError, "No symbols provided for GS::Label.create"
      end
      unless symbols.all? { |s| Symbol === s }
        fail ArgumentError, "All arguments to GS::Label.create must be symbols"
      end
    end

    def Label.label_class(symbols)
      c = Class.new
      c.class_eval do
        objects = symbols.each_with_object({}) { |s,h| h[s] = self.class.new.freeze }
        const_set :OBJECTS, objects
        symbols.each do |s|
          define_method(s) { OBJECTS[s] }
        end
      end
      c
    end
  end  # class Label
end  # class GS
