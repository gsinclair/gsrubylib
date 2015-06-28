require 'gsrubylib'

D "GS::Basic" do

  D "String" do
    S :poe do
      @poem_tab_0 = <<-EOF
Once upon a midnight dreary
  While I pondered, weak and weary
EOF
      @poem_tab_10 = <<-EOF
          Once upon a midnight dreary
            While I pondered, weak and weary
          EOF
      @poem_with_margin = %{
        | Once upon a midnight dreary
        |   While I pondered, weak and weary
      }
      @poem_without_margin = %{
        Once upon a midnight dreary
          While I pondered, weak and weary
      }
    end
    D "indent" do
      S :poe
      Eq "foo".indent(5), "     foo"
      Eq "  foo".indent(0), "  foo"
      E { "  foo".indent(-1) }
      D "multiline" do
        Eq @poem_tab_0.indent(10), @poem_tab_10
      end
    end
    
    D "trim" do
      S :poe
      D "with margin" do
        Eq @poem_with_margin.trim('|'), @poem_tab_0
      end
      D "without margin" do
        Eq @poem_without_margin.trim, @poem_tab_0
      end
    end
  end  # "String"

  D "Object" do
    D "in?" do
      T 5.in? 1..10
      T "Ruby".in? %w[Perl Ruby Python Java]
      F 17.in? 1..10
      F "C++".in? %w[Perl Ruby Python Java]
    end
    D "not_in?" do
      F 5.not_in? 1..10
      F "Ruby".not_in? %w[Perl Ruby Python Java]
      T 17.not_in? 1..10
      T "C++".not_in? %w[Perl Ruby Python Java]
    end
    D "not_nil? and non_nil?" do
      T 5.not_nil?
      T "hello"[/[aeiou]/].not_nil?
      F "hello"[/z/].not_nil?
      F nil.not_nil?
      F nil.non_nil?
      T "seven".non_nil?
    end
    D "pp_s" do
      a = [1,2,3,4,5]
      Eq a.pp_s, '[1, 2, 3, 4, 5]'
      h = { "Neil" => 37, "Jane" => 25, "Isabella" => 90, "Ugo" => 57,
            "Samuel" => 10, "Xavier" => 33, "Jeremy" => 71, "Melanie" => 44 }
      hs = h.pp_s
      T hs.scan("\n").to_a.size > 5
      Mt hs, /Neil/
      Mt hs, /Jane/
      Mt hs, /Isabella/
      Mt hs, /Melanie/
    end
    D "define_method" do
      # With no arguments
      str = "foo"
      str.define_method(:double_length) { length * 2 }
      Eq str.double_length, 6
      E(NoMethodError) { "foo".double_length }
      # With arguments
      list = [5,8,11,-3]
      list.define_method(:my_insert) { |what, where|
        slice(0...where) + [what] + slice(where..-1)
      }
      Eq list.my_insert(77, 2), [5,8,77,11,-3]
      Eq list.my_insert(77, 1), [5,77,8,11,-3]
      Eq list.my_insert(77, 0), [77,5,8,11,-3]
      E(NoMethodError) { [1,2,3].my_insert(6,2) }
    end
  end  # "Object"

  D "Enumerable" do
    D "build_hash (alias graph)" do
      squares = (4..7).build_hash { |n| [n, n**2] }
      Eq squares, { 4 => 16, 5 => 25, 6 => 36, 7 => 49 }
      h = %w(John Jane Mat William).graph { |name| [name.to_sym, name.length] }
      Eq h, { John: 4, Jane: 4, Mat: 3, William: 7 }
    end
    D "mapf (alias collectf)" do
      Eq %w(John Jane Mat William).mapf(:size),     [4,4,3,7]
      Eq %w(John Jane Mat William).collectf(:size), [4,4,3,7]
    end
  end  # "Enumerable"

  D "Hash" do
    D "apply_keys" do
      hash = { John: 4, Jane: 4, Mat: 3, William: 7 }
      hash_copy = hash.dup
      Eq hash.apply_keys { |name| name.to_s.downcase.to_sym },
           { john: 4, jane: 4, mat: 3, william: 7 }
      D "doesn't affect original" do
        Eq hash, hash_copy
      end
    end
    D "apply_values" do
      hash = { John: 4, Jane: 4, Mat: 3, William: 7 }
      hash_copy = hash.dup
      Eq hash.apply_values { |age| age + 1 },
           { John: 5, Jane: 5, Mat: 4, William: 8 }
      D "doesn't affect original" do
        Eq hash, hash_copy
      end
    end
  end  # "Hash"

  D "StringIO" do
    D "StringIO.string" do
      s = StringIO.string { |o|
        o.puts "one"
        o.puts "two"
        o.puts "three"
      }
      Eq s, "one\ntwo\nthree\n"
    end
  end  # "StringIO"

  D! "Class" do
    class Polygon
      attr_predicate    :regular?
      attr_predicate_rw :filled?
      def initialize(regular=nil)
        @regular = regular
      end
    end
    D "attr_predicate and attr_predicate_rw" do
      p = Polygon.new
      F p.regular?
      F p.filled?
      E! { p.filled = true }
      T p.filled?
      E! { p.filled = "seventeen" }
      T p.filled?
      E! { p.filled = false }
      F p.filled?
      p = Polygon.new(true)
      T p.regular?
      F p.filled?
      p = Polygon.new(-1)
      T p.regular?
      F p.filled?
      D "can't change read-only predicate" do
        E(NoMethodError) { p.regular = true }
      end
      D "Must use question mark to specify predicate name" do
        E(ArgumentError) {
          class Foo; attr_predicate :x; end
        }
        Mt Whitestone.exception.message, /question mark/
        E(ArgumentError) {
          class Foo; attr_predicate_rw :x; end
        }
        Mt Whitestone.exception.message, /question mark/
      end
    end
  end  # "Class"

end  # "GS::Basic"


