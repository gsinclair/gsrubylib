require 'gsrubylib/value'

D "GS::Value" do
  D "(Internal test) Creates correct attribute table" do
    D "For :ALL required fields" do
      table  = GS::Value.new(name: String, age: Nat, married: Bool)
                        .default(married: false)
                        .attribute_table_for_testing
      Eq table.size, 3
      no_default = GS::Value::NO_DEFAULT
      Eq table[:name],    GS::Value::Attribute.new(:name, String, no_default)
      Eq table[:age],     GS::Value::Attribute.new(:age, Nat, no_default)
      Eq table[:married], GS::Value::Attribute.new(:married, Bool, false)
    end
    D "For specified required fields" do
      table  = GS::Value.new(name: String, age: Nat, married: Bool)
                        .default(name: "John", age: 37)
                        .attribute_table_for_testing
      Eq table.size, 3
      no_default = GS::Value::NO_DEFAULT
      Eq table[:name],    GS::Value::Attribute.new(:name, String, "John")
      Eq table[:age],     GS::Value::Attribute.new(:age, Nat, 37)
      Eq table[:married], GS::Value::Attribute.new(:married, Bool, no_default)
    end
  end

  D "Can be created and used" do
    Person = GS::Value.new(name: String, age: Nat, married: Bool)
                      .default(married: false)
                      .create
    D "With everything specified" do
      p = Person.new(name: 'John', age: 19, married: true)
      Eq p.name,     'John'
      Eq p.age,      19
      Eq p.married,  true
      Eq p.married?, true
      E(NoMethodError) { p.age? }
    end
    D "With a default value left unspecified" do
      p = Person.new(name: 'John', age: 19)
      Eq p.name,     'John'
      Eq p.age,      19
      Eq p.married,  false
      Eq p.married?, false
    end
    D "Hash-like access to data" do
      p = Person.new(name: 'John', age: 19)
      Eq p[:name],     'John'
      Eq p[:age],      19
      Eq p[:married],  false
      Eq p[:married?], false
    end
  end

  D "Barfs on incomplete data" do
    Person = GS::Value.new(name: String, age: Nat, married: Bool)
                      .default(age: 40)
                      .create
    p = nil
    E(ArgumentError)  { p = Person.new(name: 'John') }
    E(ArgumentError)  { p = Person.new(name: 'Anne', age: 21) }
    E!(ArgumentError) { p = Person.new(name: 'Anne', age: 21, married: false) }
    E!(ArgumentError) { p = Person.new(name: 'Anne', married: true) }
    T p.married?
  end

  D "Barfs on data not satisfying the contract" do
    Person = GS::Value.new(name: String, age: Nat, married: Bool).create
    E(ArgumentError) { Person.new(name: [4,5,6], age: 50, married: false) }
    E(ArgumentError) { Person.new(name: 'Owen', age: -2, married: true) }
    E(ArgumentError) { Person.new(name: 'Jane', age: 5, married: nil) }
    E(ArgumentError) { Person.new(name: 'Jane', age: 5, married: 7) }
  end

  D "Equality, hashability" do
    Tuple = GS::Value.new(a: Symbol, b: Neg).create
    t1 = Tuple.new(a: :fred, b: -8)
    t2 = Tuple.new(a: :fred, b: -8)
    t3 = Tuple.new(b: -8, a: :fred)
    Eq t1, t2
    Eq t1, t3
    Eq t2, t3
    Eq t1.hash, t2.hash
    Eq t1.hash, t3.hash
    Eq t2.hash, t3.hash
    t4 = Tuple.new(a: :x, b: -1.7)
    require 'set'
    Eq Set[t1,t2,t3,t4].size, 2
  end

  D "to_s, inspect, to_hash" do
    Person = GS::Value.new(name: String, age: Nat, married: Bool).create
    p = Person.new(name: 'John', age: 50, married: false)
    Eq p.to_s, %{Person(name: "John", age: 50, married: false)}
    Eq p.inspect, p.to_s
    Eq p.to_hash, { name: 'John', age: 50, married: false }
  end

  D "Can create new value from old (with modifications)" do
    Person = GS::Value.new(name: String, age: Nat, married: Bool).create
    p = Person.new(name: 'John', age: 50, married: false)
    Eq p.name, 'John'
    Eq p.age,  50
    F  p.married?
    p = p.with(age: 51, married: true)
    Eq p.name, 'John'
    Eq p.age,  51
    T  p.married?
    D "Fails if incorrect key is applied" do
      E(ArgumentError) { p.with(salary: 10_000) }
      Mt Whitestone.exception.message, /attribute '.*?' not defined/
    end
  end

  D "Doesn't allow specification where default value fails contract" do
    E(ArgumentError) {
      Person = GS::Value.new(name: String, age: Nat, married: Bool)
                        .default(name: 56)
                        .create
    }
    Mt Whitestone.exception.message, /violates contract/
  end

end
