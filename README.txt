gsrubylib -- Gavin Sinclair's Ruby Library

First and foremost, this library contains methods I wish were defined in Ruby
itself:

    if object.in? collection
    if object.not_in? collection
    if object.not_nil?
    str = object.pp_s
    o.define_method(:add) do |x,y| x + y end

    squares = (1..10).build_hash { |n| [n, n*n] }        # Alias: graph
    squares.values.mapf(:to_s)                           # Alias: collectf
    h = squares.apply_keys { |k| k.to_s }
    h = squares.apply_values { |k| k.to_s }

    "foo".indent(4)
    "bar".tabto(4)
    USAGE = %{
      | usage: prog [-o dir] -h file...
      | where
      | -o dir outputs to DIR
      | -h prints this message
    }.trim("|")
    StringIO.string { |o| o.puts "Hi!" }

    class Person
      attr_predicate :young?
      attr_predicate_rw :successful?
    end

It also loads 'pry' and 'debuglog' and 'contracts' so I don't have to. Set
$gs_nopry and $gs_nodebuglog if those two are not wanted.


*** LABELS ***

    Result = GS::Label.create(:win, :lose, :draw)
    # ...

    case result
    when Result.win   then ...
    when Result.loose then ...               # Error!
    ...
    end

Labels are safer than symbols because they guard against misspellings. They
also “inspect” nicely.


*** VALUE OBJECTS (with Contracts validation) ***

These are read-only structs with type safety, predicate methods, copy constructors
and other conveniences.

    Person =
      GS::Value[name: String, age: Nat, married: Bool] do
        default married: false
        ... other methods ...
      end

    p = Person[name: 'John', age: 37]       # or Person.new(...)
                                            # or Person['John', 37]
    p.name
    p.age
    p.married
    p.married?                  # Auto-created because Bool type

    p.attributes                # -> [:name, :age, :married]
    p.values(:name, :married)   # -> ['John', false]
    p.values()                  # -> ['John', 37, false]

    p = p.with(age: 38)         # Create new object based on old one

    p[:age]                     # 38
    p[:salary]                  # error

    e = p.upgrade(Employee, salary: 10_000)
                                # -> Employee(name: 'John', age: 37, salary: 10_000)
                                # (Assuming Employee value class has been defined)

    p = e.downgrade(Person)     # Back where we started

    Person.info                 # -> "Person[name: String, age: Nat]"

Values are read-only structs with Contracts built-in, default values, predicate
methods, copy-constructors (with), transformers (upgrade, downgrade).  They
combine type safety, state safety and convenience.

