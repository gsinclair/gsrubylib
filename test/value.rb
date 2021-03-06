require 'gsrubylib/value'

D "GS::Value" do
  D "Can be created and used with .create" do
    Person = GS::Value.create(name: String, age: Nat, married: Bool) do
      default married: false
    end
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
    D "With a maybe-nil (i.e. optional) field" do
      X = GS::Value.create(a: Integer, b: Maybe[String])
      E! { X.new(a: 6, b: "foo") }
      E! { X.new(a: 6, b: nil) }
      E! { X.new(a: 6) }
      x = X.new(a: 6)
      Eq x.a, 6
      Eq x.b, nil
    end
    D "Hash-like access to data" do
      p = Person.new(name: 'John', age: 19)
      Eq p[:name],     'John'
      Eq p[:age],      19
      Eq p[:married],  false
      Eq p[:married?], false
    end
    D "Access to #attributes and #values" do
      p = Person.new(name: 'John', age: 19, married: true)
      Eq p.attributes, [:name, :age, :married]
      Eq p.values, ['John', 19, true]
      Eq p.values(:name), ['John']
      Eq p.values(:name, :age), ['John', 19]
      Eq p.values(:name, :age, :married), ['John', 19, true]
      Eq p.values(:name, :age, :married?), ['John', 19, true]
      Eq p.values(:married, :age), [true, 19]
      E(GS::ValueError) { p.values(:level_of_enthusiasm) }
      E(GS::ValueError) { p.values(:attributes) }
    end
    D "And also with Person[...]" do
      p = Person[name: 'Dave', age: 32, married: true]
      Eq p.name, 'Dave'
      Eq p.age,  32
      T  p.married?
      p = Person[name: 'Rita', age: 31]
      Eq p.name, 'Rita'
      Eq p.age,  31
      F  p.married?
    end
  end

  D "Can't be created with .new" do
    E(NoMethodError) { GS::Value.new(name: String) }
    Mt Whitestone.exception.message, /protected method/
  end

  D "Can create objects with positional parameters" do
    Person = GS::Value.create(name: String, age: Nat, married: Bool)
    p = Person.new('Henry', 17, false)
    Eq p.name, 'Henry'
    Eq p.age,  17
    F  p.married?
    p = Person['Henry', 17, false]
    Eq p.name, 'Henry'
    Eq p.age,  17
    F  p.married?

    D "Fails on bad input" do
      E(GS::ValueError) { Person["Steve", 83, true, "golf"] }
      Mt Whitestone.exception.message, /too many/
      E(GS::ValueError) { Person["Steve", 83] }
      Mt Whitestone.exception.message, /fails its contract/
      E(GS::ValueError) { Person["Steve", 83, :unmarried] }
      Mt Whitestone.exception.message, /fails its contract/
    end
  end

  D "Can customise the class on creation" do
    D "With no defaults" do
      Eg = GS::Value.create(a: Integer, b: Integer) do
        def sum
          a+b
        end
      end
      x = Eg[a: 7, b: 11]
      Eq x.sum, 18
    end
    D "With defaults" do
      Eg = GS::Value.create(a: Integer, b: Integer) do
        default a: 95
        def sum
          a+b
        end
      end
      x = Eg[b: 13]
      Eq x.sum, 108
    end
  end

  D "Barfs on incomplete data" do
    Person = GS::Value.create(name: String, age: Nat, married: Bool) do
      default age: 40
    end
    p = nil
    E(GS::ValueError)  { p = Person.new(name: 'John') }
    E(GS::ValueError)  { p = Person.new(name: 'Anne', age: 21) }
    E!(GS::ValueError) { p = Person.new(name: 'Anne', age: 21, married: false) }
    E!(GS::ValueError) { p = Person.new(name: 'Anne', married: true) }
    T p.married?
  end

  D "Barfs on invalid data" do
    Person = GS::Value.create(name: String, age: Nat, married: Bool)
    E(GS::ValueError) { Person.new(name: 'Alan', age: 5, married: false, x: 57) }
  end

  D "Barfs on data not satisfying the contract" do
    Person = GS::Value.create(name: String, age: Nat, married: Bool)
    E(GS::ValueError) { Person.new(name: [4,5,6], age: 50, married: false) }
    E(GS::ValueError) { Person.new(name: 'Owen', age: -2, married: true) }
    E(GS::ValueError) { Person.new(name: 'Jane', age: 5, married: nil) }
    E(GS::ValueError) { Person.new(name: 'Jane', age: 5, married: 7) }
  end

  D "Equality, hashability" do
    Tuple = GS::Value.create(a: Symbol, b: Neg)
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
    Person = GS::Value.create(name: String, age: Nat, married: Bool)
    p = Person.new(name: 'John', age: 50, married: false)
    Eq p.to_s, %{Person(name: "John", age: 50, married: false)}
    Eq p.inspect, p.to_s
    Eq p.to_hash, { name: 'John', age: 50, married: false }
  end

  D "Can create new value from old (with modifications)" do
    Person = GS::Value.create(name: String, age: Nat, married: Bool)
    p = Person.new(name: 'John', age: 50, married: false)
    Eq p.name, 'John'
    Eq p.age,  50
    F  p.married?
    p = p.with(age: 51, married: true)
    Eq p.name, 'John'
    Eq p.age,  51
    T  p.married?
    D "Fails if incorrect key is applied" do
      E(GS::ValueError) { p.with(salary: 10_000) }
      Mt Whitestone.exception.message, /invalid field/
    end
  end

  D "Can upgrade to a new value object" do
    Person   = GS::Value.create(name: String, age: Nat)
    Employee = GS::Value.create(name: String, age: Nat, title: Maybe[String], salary: Nat)
    # Test 1
    p = Person.new(name: 'Ally', age: 19)
    e = p.upgrade(Employee, title: 'Student', salary: 15000)
    Ko e, Employee
    Eq e.name,   'Ally'
    Eq e.age,    19
    Eq e.title,  'Student'
    Eq e.salary, 15000
    # Test 2
    e = p.upgrade(Employee, salary: 98100)
    Eq e.name,   'Ally'
    Eq e.age,    19
    N  e.title
    Eq e.salary, 98100

    D "Fails if incorrect additional data provided" do
      p = Person.new(name: 'Jann', age: 28)
      E(GS::ValueError) {
        e = p.upgrade(Employee, title: 'Nurse', salary: 58576, time_served: 4)
      }
      E(GS::ValueError) {
        e = p.upgrade(Employee, title: 'Nurse', salary: 'High')
      }
    end
  end

  D "Can downgrade to a new value object" do
    Person   = GS::Value.create(name: String, age: Nat)
    Employee = GS::Value.create(name: String, age: Nat, title: Maybe[String], salary: Nat)
    e = Employee.new(name: 'Ally', age: 19, title: 'Student', salary: 15000)
    p = e.downgrade(Person)
    Ko p, Person
    Eq p.name,   'Ally'
    Eq p.age,    19

    D "Fails when class is incompatible" do
      Sausage = GS::Value.create(skin: Symbol, filling: Symbol)
      e = Employee.new(name: 'Ally', age: 19, title: 'Student', salary: 15000)
      E(GS::ValueError) { e.downgrade(Sausage) }
    end
  end

  D "Can get an info string including contracts" do
    Employee = GS::Value.create(name: String, age: Nat, title: Maybe[String], salary: Nat) do
      default salary: 10000
    end
    Eq Employee.info(:short),
      %{Employee[name: String, age: Nat, title: String or nil, salary: Nat (10000)]}
    Eq Employee.info(:long), %{
      | Employee[name: String,
      |          age: Nat,
      |          title: String or nil,
      |          salary: Nat (def. 10000)]
    }.trim('|').chomp
    Eq Employee.info, Employee.info(:long)
  end

  D "Doesn't allow specification where default value fails contract" do
    E(GS::ValueError) {
      Person = GS::Value.create(name: String, age: Nat, married: Bool) do
        default name: 56
      end
    }
    Mt Whitestone.exception.message, /violates contract/
  end

end
