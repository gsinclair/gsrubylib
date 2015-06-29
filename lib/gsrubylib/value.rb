# lib/gsrubylib/value.rb
#
# Class:       GS::Value
# Description: Allows the creation of value objects (read-only structs) with
#              nice features like type checking, predicate methods, and default
#              values. Oh, and creating a new object from an old one.

require 'gsrubylib'
require 'ap'

class GS

  # Value is like Ruby's Struct except the classes it creates are read-only.
  # That is, it creates "value objects" whose state is not subject to change.
  # There are additional features:
  #  * types are specified and enforced when a new object is created
  #    * this uses the excellent "contracts.ruby" library
  #  * default values
  #  * predicate access methods for boolean attributes
  #    * e.g. person.married? as an alternative to person.married
  #  * create new objects with 'with'
  #  * upgrade or downgrade to different (compatible) value object types
  #
  # Example 1
  #
  #   Person = Value.create(name: String, age: Nat, married: Bool)
  #   p = Person[name: 'Sam', age: 37, married: false]
  #   p.name
  #   p.age
  #   p.married?
  #   p = p.with(married: true)
  #
  # Example 2
  #
  #   Person = Value.create(name: String, age: Nat, married: Bool) do
  #     default married: false
  #   end
  #   p = Person['Anna', 16]       # can specify parameters positionally
  #   p = Person.new('Anna', 16)   # can use 'new' if you like
  #   p.values                     # -> ['Anna', 37, false]
  #   p.values(:married?, :age)    # -> [false, 37]
  #   p.attributes                 # -> [:name, :age, :married]
  #
  #
  # Example 3
  #
  #   Note = Value.create(base:       Symbol,
  #                       accidental: Or[:flat,:sharp,nil],
  #                       octave:     (1..8)) do
  #
  #     default accidental: nil, octave: 4
  #
  #     def semitone_lower
  #       ...
  #     end
  #
  #     def semitone_higher
  #       ...
  #     end
  #   end
  #
  #   middle_c = Note[:C]
  #   middle_d = middle_c.semitone_higher.semitone_higher
  #
  # Example 4
  #
  #   Person   = Value.create(name: String, age: Nat)
  #   Employee = Value.create(name: String, age: Nat, salary: Nat)
  #
  #   p = Person['Rob', 29]
  #   e = p.upgrade(Employee, salary: 48000]
  #   p = e.downgrade(Person)
  #
  class Value
    # An attribute table looks something like this when initially populated:
    #   { name: Attribute(:name,    String,  NO_DEFAULT),
    #     age:  Attribute(:age,     Nat,     NO_DEFAULT),
    #     age:  Attribute(:married, Bool,    NO_DEFAULT) }
    #
    # After the 'default' method is called in class scope, some of the
    # Attributes will have a default value.
    class Attribute < Struct.new(:name, :type, :default)
      def default?
        self.default != NO_DEFAULT
      end
    end
    NO_DEFAULT = Object.new.freeze
    class ValueObjectBase; end            # Defined later.

    # Value.create()
    #
    # See class documentation for examples.
    #
    Contract HashOf[Symbol, Any], Maybe[Proc] => Class
    def Value.create(args, &block)
      Value.new(args).create(&block)
    end

    class << self
      protected :new
    end

    #Contract HashOf[Symbol, Any] => Any
    def initialize(args)
      @attributes = {}
      args.each do |attr_name, type|
        @attributes[attr_name] = Attribute.new(attr_name, type, NO_DEFAULT)
      end
    end

    #Contract None => Class
    def create(&block)
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
      if block_given?
        c.class_eval(&block)         # or should it be class_exec ?
      end
      c
    end

    private

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

        # Two options for providing arguments to #initialize.
        # 1. A hash of field=>value pairs.
        # 2. A varargs list of positional parameters.
        # We get ValueObjectBase to do all the work.
        define_method(:initialize) do |*args|
          begin
            validate_and_store_data(*args)
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

    # ValueObjectBase -- base class for value objects
    #
    # This class is not for direct use. Users create value objects with Value[...],
    # which returns an anonymous class that extends this one. The code in Value
    # defines the class methods _attr_names_ and _attr_table_. These are needed for
    # the code in ValueObjectBase to function. The #initialize in the subclass will
    # call validate_and_store_data() implemented below, which sets @data for
    # other methods to use.
    #
    # Summary: the methods in ValueObjectBase are free to use:
    #  * class methods _attr_names_ and _attr_table_
    #    * instance methods of the same name are created for convenience
    #  * instance method @data
    #
    # Instance methods of interest to users of value objects:
    #  * []      e.g. p[:name]
    #  * attributes
    #  * values
    #  * with
    #  * upgrade
    #  * downgrade
    #  * to_s
    #  * inspect
    #  * ==
    #
    # Class methods of interest:
    #  * default (while defining the value object class)
    #  * info    (e.g. Person.info to get string describing the class)
    class ValueObjectBase

      # ++++ ValueObjectBase plumbing

      class << self
        # A ValueObjectBase object is only to be created via Value[...].
        private :new
      end

      # Helpful method to access attribute names within an instance method.
      def _attr_names_
        self.class._attr_names_
      end

      # Helpful method to access the attribute table within an instance method.
      def _attr_table_
        self.class._attr_table_
      end

      #Contract HashOf[Symbol, Any] => Nil
      def self.default(args)
        args.each do |attr_name, default_value|
          attribute = _attr_table_.fetch(attr_name)   # The object we're updating.
          contract = attribute.type
          if Contract.valid?(default_value, contract)
            attribute.default = default_value
          else
            raise ArgumentError,
              "Value: default value for '#{attr_name}' violates contract #{contract}"
          end
        end
      rescue KeyError => e
        raise ArgumentError, "Value: can't set default for invalid key"
      end

      # *args could be:
      # 1. A list of values equal in number to the list of attributes, except
      #    for possible default values at the end.
      # 2. A single argument being a hash of attributes to values.
      #
      # If the value object has only one attribute (odd) and it's a hash, then
      # how do we know whether this is being called positionally or keywordly?
      # In that case, we can see what's inside the hash. A very special case...
      def validate_and_store_data(*args)
        if args.size == 1 and args.first.is_a? Hash
          validate_and_store_data_hash(args.first)
        else
          validate_and_store_data_list(args)
        end
      end
      protected :validate_and_store_data

      def validate_and_store_data_hash(data)
        unless Contract.valid?(data, Hash[Symbol,Any])
          raise ArgumentError, "Value: invalid arguments; need field=>value hash"
        end
        # Now validate it.
        dodgy_fields = data.keys - self.attributes
        unless dodgy_fields.empty?
          raise ArgumentError, "Value: invalid field(s): #{dodgy_fields.join(', ')}"
        end
        _attr_table_.values.each do |attribute|
          name = attribute.name
          value_given = (data.key? name)
          if not value_given and attribute.default?
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
      private :validate_and_store_data_hash

      def validate_and_store_data_list(list)
        # Turn it into a hash and get the other method to do the work.
        # First check we don't have too many parameters. Too few may be OK if
        # there are defaults.
        if list.size > _attr_names_.size
          raise ArgumentError, "Value: too many values provided"
        end
        data = _attr_names_.zip(list).take(list.size)
        data = Hash[data]
        validate_and_store_data_hash(data)
      end

      def _key_lookup_(key)
        # Translation table, allowing for idiomatic predicate lookups:
        #   :name       ->    value
        #   :age        ->    value
        #   :married    ->    value
        #   :married?   ->    value
        @table ||= (
          h = {}
          attributes.each do |attr_name|
            h[attr_name] = @data[attr_name]
            if _attr_table_[attr_name].type == Bool
              h[(attr_name.to_s + '?').intern] = @data[attr_name]
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
      def self.[](*args)
        new(*args)
      end

      def [](key)
        _key_lookup_(key)
      end

      def attributes
        _attr_names_
      end

      def values(*keys)
        if keys.empty?
          @data.values
        else
          keys.map { |k| _key_lookup_(k) }
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

      # Person.info -> "Person[name: String, age: Nat]"
      class << self
        def info(mode=:long)
          name       = self.name
          attributes = self._attr_table_.values
          if mode == :short
            info_short(name, attributes)
          else
            info_long(name, attributes)
          end
        end

        def info_short(name, attributes)
          content = attributes.map { |a|
            name_str, type_str, default_str = preprocess_content(a)
            unless default_str.empty?
              default_str = " (#{default_str})"
            end
            "#{name_str}: #{type_str}#{default_str}"
          }.join(', ')
          classname = self.name
          "#{classname}[#{content}]"
        end

        def info_long(name, attributes)
          content = attributes.map { |a|
            name_str, type_str, default_str = preprocess_content(a)
            unless default_str.empty?
              default_str = " (def. #{default_str})"
            end
            "#{name_str}: #{type_str}#{default_str}"
          }.join(",\n")
          lines = content.split("\n")
          classname = self.name
          line1  = "#{classname}[#{lines.shift}\n"
          spaces = " " * (classname.length+1)
          rest   = lines.map { |line| spaces + line }.join("\n")
          final_result = line1 + rest + ']'
        end

        Contract Attribute => [String, String, String]
        def preprocess_content(a)
          type_str = a.type.to_s.gsub(/Contracts::/, '')
          default_str =
            if a.default? then a.default.to_s else "" end
          [a.name.to_s, type_str, default_str]
        end
      end

    end  # class ValueObjectBase

    # =======================

  end  # class Value
end  # class GS
