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
        define_method(:initialize) { |symbol| @symbol = symbol }
        const_set :OBJECTS,
          symbols.each_with_object({}) { |sym, hash|
            hash[sym] = self.new(sym).freeze
          }
        define_method(:to_s)    { @symbol.to_s }
        define_method(:to_sym)  { @symbol }
        define_method(:symbol)  { @symbol }
        define_method(:inspect) { "#{self.class.name}.#{symbol}" }
        define_method(:==)      { |other| self.object_id == other.object_id }
        define_method(:hash)    { @symbol.hash }
      end
      # Define the methods by which each label is known (e.g. TrafficLight.red)
      symbols.each do |sym|
        c.define_singleton_method(sym) { c.const_get(:OBJECTS)[sym] }
      end
      c.define_singleton_method(:inspect) {
        x = symbols.join(' ')
        "#{c.name}[#{x}]"
      }
      c.define_singleton_method(:by_symbol) { |sym|
        const_get(:OBJECTS)[sym] or raise ArgumentError,
          "#{c.name}.#{sym} is not defined"
      }
      c.define_singleton_method(:[]) { |arg|
        case arg
        when Symbol then by_symbol(arg)    # Allow Colour[:red]
        when self   then arg               # Allow Colour[Colour.red]
        else
          raise ArgumentError, "Can't convert #{arg.inspect} to #{c.name}"
        end
      }
      c
    end

  end  # class Label
end  # class GS
