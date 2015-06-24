require 'gsrubylib/label'
require 'pry'

D 'GS::Label' do
  D 'Type can be created (TrafficLightLabel)' do
    TrafficLightLabel = GS::Label.create(:green, :amber, :red)
    #TrafficLightLabel = GS::Label::TrafficLightLabel
    T TrafficLightLabel.is_a? Class
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

  D 'Can use [] to get label object from symbol' do
    Eq TrafficLightLabel[:red],   TrafficLightLabel.red
    Eq TrafficLightLabel[:amber], TrafficLightLabel.amber
    Eq TrafficLightLabel[:green], TrafficLightLabel.green
    D 'Raises ArgumentError if given invalid symbol' do
      E(ArgumentError) { TrafficLightLabel[:blue] }
      E(ArgumentError) { TrafficLightLabel[:nil] }
    end
    D 'Is idempotent -- can accept TrafficLightLabel objects too' do
      Eq TrafficLightLabel[TrafficLightLabel.red],   TrafficLightLabel.red
      Eq TrafficLightLabel[TrafficLightLabel.amber], TrafficLightLabel.amber
      Eq TrafficLightLabel[TrafficLightLabel.green], TrafficLightLabel.green
      D 'In fact, returns identical objects in this case' do
        Id TrafficLightLabel[TrafficLightLabel.red], TrafficLightLabel.red
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
    Eq TrafficLightLabel.inspect, 'TrafficLightLabel[green amber red]'
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
