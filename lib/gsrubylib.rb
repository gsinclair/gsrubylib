# Gavin Sinclair's Ruby library (i.e. all the things I wish were in Ruby).

# Now I don't have to load these separately in all my code.
require 'debuglog'   unless $gs_nodebuglog
require 'pry'        unless $gs_nopry
require 'contracts'
include Contracts

# A containing class into which several classes are defined so as not to pollute
# the top-level namespace.
#  * GS::Basic        (defines methods in core classes; don't use this directly)
#  * GS::Label        (create type-safe labels)
#  * GS::ErrorHelper  (not programmed or properly considered yet)
class GS
end

require 'gsrubylib/basic'
  # Defines several additions to built-in classes:
  #   Object
  #     in?   not_nil?   non_nil?   pp_s   define_method
  #   Enumerable
  #     build_hash  (graph)   mapf  (collectf)
  #   Hash
  #     apply_keys   apply_values
  #   String
  #     indent   tabto   trim
  #   StringIO
  #     StringIO.string
  #   Class
  #     attr_predicate  attr_predicate_rw

# Useful method to remind me of the methods I have available.
def GS.added_methods
  debug "gsrubylib added methods:"
  GS::Basic.extension_methods.each do |m|
    debug m.indent(2)
  end
end

__END__


  Maybe a colourful exception printer
    i.e. catch all exceptions and print the error and stacktrace colorfully

  I think my SuckerHelper module can be partially extracted as a general helper
  with useful error messages etc.  ErrorHelper might be a good name.

Be safe in modifying classes, like I was in the Extensions project. Check
whether a method exists before defining it. And consider being sensitive to Ruby
versions. For instance, let's say I want to define Enumerable#graph in 1.9 and 2.0
but not 2.1:
  module Enumerable
    GsRubyLib.define_method(Enumerable, :instance, :graph, [1.9, 2.0]) do
      def graph(&block)
        result = {}
        self.each do |x|
          val = yield x
          result[x] = val
        end
        result
      end
    end
  end

This way, I can build a record inside GsRubyLib of what has been defined.

Enum, like:
  TrafficLightState = Enum.new(:red, :amber, :green)
  TrafficLightState(:red)       -> TrafficLightState.red
  TrafficLightState(:blue)      -> TypeError or EnumError or something
  TrafficLightState(nil)        -> error
  r = TrafficLightState.red
  r.symbol                      -> :red
  r.to_s                        -> 'red'
  r.inspect                     -> 'TrafficLightState.red'
  TrafficLightState === :green  -> true     (have to think about this)
  TrafficLightState.to_s        -> 'TrafficLightState'
  TrafficLightState.inspect     -> 'GS::Enum::TrafficLightState[red amber green]'

Probably best to make the Enum class GS::Enum, as it's easy to believe there
could be another top-level Enum class in some library.

Actually, I think another name, like Label, could be better.  Enum objects
should have a value and be combinable, like F_READ | F_BINARY.  My conception is
nothing more than a typo-safe symbol.

Improvements to debuglog:
 * a way to turn it off (global variable or DebugLog.silent = true or sth)
 * variety of output types (:pp, :yaml, :ap, ... do I already have this?)
 * DebugLog.help to print a help message to the log file
 * verbose mode to include stacktrace information
 * ensure the first line of the log file identifies the 'debuglog' gem
