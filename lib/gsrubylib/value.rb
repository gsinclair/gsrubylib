# lib/gsrubylib/value.rb
#
# Class:       GS::Value
# Description: Allows the creation of value objects (read-only structs) with
#              nice features like type checking, predicate methods, and default
#              values. Oh, and creating a new object from an old one.

require 'gsrubylib'
require 'ap'

class GS

  # Example:
  #   Person = GS::Value.new(name: String, age: Nat, married: Bool)
  #                     .default(married: false)
  #                     .create
  class Value
    class Attribute < Struct.new(:name, :type, :default)
    end
    NO_DEFAULT = Object.new.freeze

    # The attribute table, @attributes, looks like this when fully populated:
    #   { name: Attribute(:name,    String,  NO_DEFAULT),
    #     age:  Attribute(:age,     Nat,     NO_DEFAULT),
    #     age:  Attribute(:married, Bool,    false) }
    Contract HashOf[Symbol, Any] => Any
    def initialize(args)
      @attributes = {}
      args.each do |attr_name, type|
        @attributes[attr_name] = Attribute.new(attr_name, type, NO_DEFAULT)
      end
    end

    Contract HashOf[Symbol, Any] => Value
    def default(args)
      check_attributes_are_legit(args.keys)
      args.each do |attr_name, default_value|
        @attributes[attr_name].default = default_value
      end
      self
    end

    Contract None => Class
    def create()
      # How to do this?
      # Create the class object, then call define_method and define_class_method
      # on it to create the methods:
      #  - initialize
      #    * this needs to raise an error if
      #      * an input doesn't satisfy the contract for that attribute
      #      * a required attribute is missing
      #  - each of the attribute methods
      #    - predicate method instead where appropriate
      #  - with (copy constructor)
      #  - to_s
      #  - inspect
      #  - hash
      #  - ==
      c = Class.new
      c.const_set(:ATTR_NAMES, @attributes.keys)
      make_initialize(c)
      make_attribute_methods(c)
      make_with_method(c)
      make_other_methods(c)
      c
    end

    Contract None => HashOf[Symbol, Attribute]
    def attribute_table_for_testing
      @attributes
    end

    private
    def check_attributes_are_legit(args)
      unless x = args.find { |arg| @attributes.key? arg }
        raise ArgumentError, "Value: attribute '#{x}' doesn't exist"
      end
    end

    def make_initialize(c)
      attributes = @attributes
      c.class_eval do
        # Initialize takes a hash of field=>value pairs.
        define_method(:initialize) do |data|
          unless Contract.valid?(data, Hash[Symbol,Any])
            raise ArgumentError, "Invalid arguments; need field=>value hash"
          end
          # Now validate it.
          dodgy_fields = data.keys - attributes.keys
          unless dodgy_fields.empty?
            raise ArgumentError, "Invalid fields: #{dodgy_fields.join(', ')}"
          end
          attributes.values.each do |attribute|
            name = attribute.name
            value_given = (data.key? name)
            if not value_given and attribute.default != NO_DEFAULT
              data[name] = attribute.default
            end
            unless Contract.valid?(data[name], attribute.type)
              message = StringIO.string { |o|
                o.puts "Value for attribute '#{name}' fails its contract"
                o.puts "  Contract: #{attribute.type}"
                o.puts "     Value: #{data[name].inspect}"
              }
              raise ArgumentError, message
            end
          end
          # Now that the data has been validated, save it for later.
          @data = data.freeze
        end
      end  # class_eval
    end  # make_initialize

    def make_attribute_methods(c)
      @attributes.each_value do |attribute|
        method_name = attribute.name.to_s
        c.class_eval do
          define_method(method_name) do
            @data[attribute.name]
          end
        end
        if attribute.type == Bool
          method_name << '?'
          c.class_eval do
            define_method(method_name) do
              @data[attribute.name]
            end
          end
        end
      end
    end

    def make_with_method(c)
    end

    def make_other_methods(c)
      attributes = @attributes
      c.class_eval do
        define_method(:to_s) do
          self.class.name + ": (data to be added)"
        end
        define_method(:inspect) do
          self.to_s
        end
        define_method(:to_hash) do
          @data
        end
        define_method(:eql?) do |other|
          self.class == other.class and self.to_hash == other.to_hash
        end
        define_method(:==) do |other|
          self.class == other.class and self.to_hash == other.to_hash
        end
        define_method(:hash) do
          self.to_hash.hash
        end
      end
    end

  end  # class Value
end  # class GS
