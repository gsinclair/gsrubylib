gsrubylib -- Gavin Sinclair's Ruby Library

First and foremost, this library contains methods I wish were defined in Ruby
itself:

    if object.in? collection
    if object.not_nil?                                   # Alias non_nil?
    str = object.pp_s
    o.define_method(:add) do |x,y| x + y end

    squares = (1..10).build_hash { |n| [n, n*n] }        # Alias: graph
    squares.values.mapf(:to_s) collectf                  # Alias: collectf
    h = squares.apply_keys { |k| k.to_s }
    h = squares.apply_values { |k| k.to_s }

    “foo”.indent(4)
    “bar”.tabto(4)
    USAGE = %{
      | usage: prog [-o dir] -h file...
      | where
      | -o dir outputs to DIR
      | -h prints this message
    }.trim("|")
    StringIO.string { |o| o.puts “Hi…” }

    class Person
      attr_predicate :young
      attr_predicate_rw :successful
    end

It also loads 'pry' and 'debuglog' so I don't have to. Set $gs_nopry and
$gs_nodebuglog if these are not wanted.

Next up is Labels.

    Result = GS::Label.create(:win, :lose, :draw)
    # ...

    case result
    when Result.win   then ...
    when Result.loose then ...               # Error!
    ...
    end

Planned: Value objects that can be used with Contracts.

    Person = Contracts::Value.new(name: String, age: Nat, married: Boolean)
                             .default(married: false)
                             .create

    p = Person.new(name: 'John', age: 37)
    p.name
    p.age
    p.married
    p.married?   # Auto-created because Boolean type

    p.values(:name, :married)   # -> ['John', false]
    p.values()                  # -> ['John', 37, false]

    p.with(age: 38)

    p[:age]
    p[:salary]                  # error

    Person[name: String, age: Nat]
    Person.info                 # -> "Person[name: String, age: Nat]"

    # Speculative, but nice idea:
    p.upgrade(Employee, salary: 10_000)
                                # -> Employee(name: 'John', age: 37, salary: 10_000)
                                # (Assuming Employee value class has been defined)
