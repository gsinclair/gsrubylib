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
    class ValueObjectBase; end            # Defined later.

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
        contract = @attributes[attr_name].type
        if Contract.valid?(default_value, contract)
          @attributes[attr_name].default = default_value
        else
          raise ArgumentError,
            "Value: default value for '#{attr_name}' violates contract #{contract}"
        end
      end
      self
    end

    Contract None => Class
    def create()
      # We return an anonymous class that extends ValueObjectBase.
      # Methods we define:
      #  - ._attr_names_   (easy access to the names)
      #  - ._attr_table_   (the full metadata)
      #  - #initialize (sets @data)
      #    * this needs to raise an error if
      #      * an input doesn't satisfy the contract for that attribute
      #      * a required attribute is missing
      #      (Hopefully ValueObjectBase can support this with a ._validate_data_
      #       method.)
      #  - #each of the attribute methods
      #    - predicate methods in addition where appropriate
      #
      # ValueObjectBase handles all the other parts, making use of _attr_names_,
      # _attr_table_ and @data where needed:
      #     []                          p[:name]
      #     attributes
      #     values
      #     with                        p.with(age: 57)
      #     to_s, inspect
      #     hash, eql?, ==
      #     to_hash
      #
      c = Class.new(ValueObjectBase)
      make_metadata_methods(c)
      make_initialize(c)
      make_attribute_methods(c)
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

    def make_metadata_methods(c)
      attributes = @attributes
      c.define_singleton_method(:_attr_names_) { attributes.keys }
      c.define_singleton_method(:_attr_table_) { attributes }
    end

    def make_initialize(c)
      c.class_eval do
        class << self
          public :new
        end

        # Initialize takes a hash of field=>value pairs.
        # We get ValueObjectBase to do all the work.
        define_method(:initialize) do |data|
          begin
            validate_and_store_data(data)
          rescue ArgumentError => e
            raise ArgumentError, e.message
          end
        end
      end
    end

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

    # =======================

    class ValueObjectBase
      # When a subclass is created, it will have class methods _attr_names_ and
      # _attr_table_.
      # When an object is created, its initialize will call validate_and_store_data(),
      # implemented below, which sets @data for other methods to use.
      # Summary: the methods below are free to use:
      #  * class methods _attr_names_ and _attr_table_
      #  * instance method @data

      # ++++ ValueObjectBase plumbing

      class << self
        private :new
      end

      def validate_and_store_data(data)
        unless Contract.valid?(data, Hash[Symbol,Any])
          raise ArgumentError, "Value: invalid arguments; need field=>value hash"
        end
        # Now validate it.
        dodgy_fields = data.keys - self.attributes
        unless dodgy_fields.empty?
          raise ArgumentError, "Value: invalid field(s): #{dodgy_fields.join(', ')}"
        end
        self.class._attr_table_.values.each do |attribute|
          name = attribute.name
          value_given = (data.key? name)
          if not value_given and attribute.default != GS::Value::NO_DEFAULT
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
      protected :validate_and_store_data

      def _key_lookup_(key)
        # Translation table, allowing for idiomatic predicate lookups:
        #   :name       ->    :name
        #   :age        ->    :age
        #   :married    ->    :married
        #   :married?   ->    :married
        @table ||= (
          h = {}
          attributes.each do |attr_name|
            h[attr_name] = attr_name
            if self.class._attr_table_[attr_name].type == Bool
              h[(attr_name.to_s + '?').intern] = attr_name
            end
          end
          h
        )
        @table.fetch(key)
      rescue KeyError
        raise ArgumentError, "Value: invalid field '#{key}'"
      end

      # ---- ValueObjectBase plumbing over. Now the "real" methods.

      # Alternative constructor: p = Person[name: 'John', age: 39]
      def self.[](data)
        new(data)
      end

      def [](key)
        key = _key_lookup_(key)
        @data[key]
      end

      def attributes
        self.class._attr_names_
      end

      def values(*keys)
        if keys.empty?
          @data.values
        else
          keys = keys.map { |k| _key_lookup_(k) }
          @data.values_at(*keys)
        end
      end

      def with(new_data)
        unless Contract.valid?(new_data, HashOf[Symbol,Any])
          raise ArgumentError, "Value: invalid argument to 'with'"
        end
        begin
          new_data = @data.merge(new_data)
          self.class.new(new_data)
        rescue ArgumentError => e
          raise ArgumentError, e.message
        end
      end

      def upgrade(klass, extra_data)
        klass.new(@data.merge(extra_data))
      end

      def downgrade(klass)
        required_attributes = klass._attr_names_
        data = @data.select { |k,v| required_attributes.include? k }
        klass.new(data)
      end

      def to_s
        string = @data.map { |k,v| "#{k}: #{v.inspect}" }.join(', ')
        "#{self.class.name}(#{string})"
      end
      def inspect() to_s end
      def hash() self.to_hash.hash end
      def eql?(other) self.class == other.class and self.to_hash == other.to_hash end
      def ==(other) self.class == other.class and self.to_hash == other.to_hash end
      def to_hash() @data end
    end  # class ValueObjectBase

    # =======================

  end  # class Value
end  # class GS
