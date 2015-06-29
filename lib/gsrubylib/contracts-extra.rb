# Extra stuff for Contracts.ruby.

# NOTE I do not intend to preserve InRange; I intend to push for (1..10) to be
# a useful spec in itself. But that requires changing Contracts code, so I will
# keep this here for use in the meantime.
#
# RangeOf[type] will stay, and hopefully make its way in to Contracts.
#
# e.g. InRange[(1..10)]
# e.g. InRange[(1..10), Nat]
# e.g. InRange[(1..10), Float]
class InRange < CallableClass
  def initialize(range, type=nil)
    @range = range
    @type  = type || Any
  end

  def valid?(val)
    @range.include?(val) and Contract.valid?(val, @type)
  end
end

# e.g. RangeOf[Date]
class RangeOf < CallableClass
  def initialize(type)
    @type = type
  end

  def valid?(val)
    val.is_a? Range and
      Contract.valid?(val.first, @type)
  end
end
