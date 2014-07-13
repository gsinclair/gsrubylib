require 'gsrubylib/label'
require 'pry'

class GS::Label
  class TrafficLightLabel
    def initialize(symbol)
      @symbol = symbol
      self.freeze
    end
    VALUES = { red: TrafficLightLabel.new(:red),
               amber: TrafficLightLabel.new(:amber),
               green: TrafficLightLabel.new(:green) }.freeze
    private :initialize
    def self.red; VALUES[:red]; end
    def self.amber; VALUES[:amber]; end
    def self.green; VALUES[:green]; end
    def symbol; @symbol; end
    def to_sym; @symbol; end
    def to_s; @symbol.to_s; end
    def inspect; "TrafficLightLabel.#{@symbol}"; end
    def TrafficLightLabel.symbols; VALUES.keys; end
    def TrafficLightLabel.inspect
      list = symbols.map(&:to_s).join(' ')
      "GS::Label::TrafficLightLabel[#{list}]"
    end
    def TrafficLightLabel.by_symbol(symbol)
      VALUES.fetch(symbol)
    rescue KeyError
      fail ArgumentError, "No TrafficLightLabel with symbol #{symbol.inspect}"
    end
    def ==(other)
      TrafficLightLabel === other and @symbol == other.symbol
    end
    def hash; @symbol.hash; end
  end  # class TrafficLightLabel
end  # module/class GS::Label

#
# All tests pass, so now all I have TODO is write the code to _generate_ this
# class instead of typing it in myself.
#

module Kernel
  def TrafficLightLabel(arg)
    case arg
    when Symbol then TrafficLightLabel.by_symbol(arg)
    when TrafficLightLabel then arg
    else
      fail ArgumentError, "Can't convert #{arg.inspect} to TrafficLightLabel"
    end
  end
end

D 'GS::Label' do
  D 'Type can be created (TrafficLightLabel)' do
    #TrafficLightLabel = GS::Label.create(:green, :amber, :red)
    TrafficLightLabel = GS::Label::TrafficLightLabel
    T Class === TrafficLightLabel
    D 'Methods exist (TrafficLightLabel.red etc.)' do
      N! TrafficLightLabel.red
      Ko TrafficLightLabel.red,   TrafficLightLabel
      Ko TrafficLightLabel.amber, TrafficLightLabel
      Ko TrafficLightLabel.green, TrafficLightLabel
    end
    D 'But not any old method' do
      E(NoMethodError) { TrafficLightLabel.blue }
    end
  end
  D 'Corresponding function is created to validate symbols' do
    Eq TrafficLightLabel(:red),   TrafficLightLabel.red
    Eq TrafficLightLabel(:amber), TrafficLightLabel.amber
    Eq TrafficLightLabel(:green), TrafficLightLabel.green
    D 'Raises ArgumentError if given invalid symbol' do
      E(ArgumentError) { TrafficLightLabel(:blue) }
      E(ArgumentError) { TrafficLightLabel(:nil) }
    end
    D 'Is idempotent -- can accept TrafficLightLabel objects too' do
      Eq TrafficLightLabel(TrafficLightLabel.red),   TrafficLightLabel.red
      Eq TrafficLightLabel(TrafficLightLabel.amber), TrafficLightLabel.amber
      Eq TrafficLightLabel(TrafficLightLabel.green), TrafficLightLabel.green
      D 'In fact, returns identical objects in this case' do
        Id TrafficLightLabel(TrafficLightLabel.red), TrafficLightLabel.red
      end
    end
  end
  D "Can't call :new on TrafficLightLabel" do
    E { TrafficLightLabel.new }
  end
  D 'Conversion/convenience methods to_s, to_sym, symbol inspect' do
    Eq TrafficLightLabel.red.to_s,    'red'
    Eq TrafficLightLabel.red.to_sym,  :red
    Eq TrafficLightLabel.red.symbol,  :red
    Eq TrafficLightLabel.red.inspect, 'TrafficLightLabel.red'
  end
  D 'TrafficLightLabel.inspect' do
    Eq TrafficLightLabel.inspect, 'GS::Label::TrafficLightLabel[red amber green]'
  end
  D 'TrafficLightLabel implements equality, identity, and hash sensibly' do
    Eq TrafficLightLabel.amber.hash, :amber.hash
    Eq TrafficLightLabel.green.hash, :green.hash
    Eq TrafficLightLabel.red, TrafficLightLabel.red
    Id TrafficLightLabel.red, TrafficLightLabel.red
  end
  D 'TrafficLightLabel === TrafficLightLabel.red is true' do
    T { TrafficLightLabel === TrafficLightLabel.red   }
    T { TrafficLightLabel === TrafficLightLabel.amber }
    T { TrafficLightLabel === TrafficLightLabel.green }
  end
  xD 'Can only call GS::Label.new with symbols, and must be at least one symbol' do
    E(ArgumentError) { GS::Label.create(:one, :two, 3) }
    E(ArgumentError) { GS::Label.create() }
  end
end
