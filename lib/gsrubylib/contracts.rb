require 'contracts'

class Object
  include Contracts
end

module Contracts
  # Some added or aliased contracts that I'd like

  Int = Integer  # To go with Nat, Pos, Neg
  Str = String

  NamedArgs = KeywordArgs
  Opt = Optional
end
