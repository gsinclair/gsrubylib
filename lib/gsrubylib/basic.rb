# lib/gsrubylib/basic.rb
#   * Defines the infrastructure for implementing new methods in core classes.
#   * Code taken from my old (2004) "Ruby/Extensions" project.
#                        [ https://github.com/rubyblackbelt/ruby_extensions ]
#   * Usage:
#       GS::Basic.implement(Hash, :apply_keys, :instance) do
#         class Hash
#           def apply_keys(&block)
#             h = Hash.new(&default_proc)
#             self.each do |key, value|
#               new_key = &block.call(key)
#               h[new_key] = value
#             end
#           end
#         end
#       end
#   * Benefits of this wrapper:
#     * If the specified method is already defined, it won't be overwritten, and
#       a message is printed to STDERR.
#     * It adds the information to the list of defined methods, so you can call
#       GS::Basic.extension_methods and get a list.
#     * It raises an error if you _don't_ define the method you say you will
#       define.
#   * TODO: add a parameter to allow extension methods to be sensitive to the
#     Ruby version.

# NOTE: At the bottom of this file, 'basic/methods' is required, which is where
# the actual method implementations are.

#
# For what reason does Ruby define Module#methods, Module#instance_methods,
# and Module#method_defined?, but not Module#instance_method_defined? ?
#
# No matter, extending standard classes is the name of the game here.
#
class Module
  if Module.method_defined?(:instance_method_defined?)
    STDERR.puts "Warning: Module#instance_method_defined? already defined; not overwriting"
  else
    def instance_method_defined?(_method)
      self.method_defined?(_method.to_sym)
    end
  end

  if Module.method_defined?(:module_method_defined?)
    STDERR.puts "Warning: Module#module_method_defined? already defined; not overwriting"
  else
    def module_method_defined?(_method)
      singleton_methods(false).find { |m| m == _method.to_sym }
    end
  end
end

class GS
  class Basic

    class << Basic
      @@extension_methods = []

      #
      # The list of methods implemented in this project.
      #
      def extension_methods
        @@extension_methods
      end

      #
      # Return the name of the project.  To be used in error messages, etc., for
      # consistency.
      #
      def project_name
        "GS::Basic"
      end

      #
      # Wraps around the implementation of a method, emitting a warning if the
      # method is already defined.  Returns true to indicate - false to indicate
      # failure (i.e. method is already defined).  Raises an error if the
      # specified method is not actually implemented by the block.
      #
      def implement(_module, _method, _type=:instance)
        raise "Internal error: #{__FILE__}:#{__LINE__}" unless
          _module.is_a? Module and
          _method.is_a? Symbol and
          _type == :instance or _type == :class or _type == :module

        fullname = _module.to_s + string_rep(_type) + _method.to_s

        if _defined?(_module, _method, _type)
          STDERR.puts "#{project_name}: #{fullname} is already defined; not overwriting"
          return false
        else
          #pry binding if _method == :attr_predicate
          yield # Perform the block; presumably a method implementation.
          #pry binding if _method == :attr_predicate
          if _method == :initialize and _type == :instance
            # Special case; we can't verify this.
            @@extension_methods<< "#{_module}::new"
          else
            unless _defined?(_module, _method, _type)
              raise "#{project_name}: internal error: was supposed to implement " +
                "#{fullname}, but it didn't!"
            end
            @@extension_methods << fullname
          end
          return true
        end
      end


      # See whether the given module implements the given method, taking account
      # of the type (class/instance) required.
      def _defined?(_module, _method, _type)
        case _type
        when :instance
          _module.instance_method_defined?(_method) # See definition above.
        when :class, :module
          _module.module_method_defined?(_method)   # See definition above.
        end
      end
      private :_defined?


      # Return the string representation of the given method type.
      def string_rep(method_type)
        case method_type
        when :instance then "#"
        when :class    then "."
        when :module   then "."
        else
          nil
        end
      end
      private :string_rep
    end
  end    # class Basic
end  # class GS



#
#
#   Now load the actual method implementations.
#
#

require 'gsrubylib/basic/methods'

