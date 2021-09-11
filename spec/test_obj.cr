class TestObj
  include Tracer

  @@log : Hash(Tuple(String, UInt128), Array(Time::Span)) = Hash(Tuple(String, UInt128), Array(Time::Span)).new {|h,k| h[k] = [] of Time::Span}

  @@trace_tracker : Hash(String, String) = Hash(String, String).new

  def self.log
    @@log
  end

  def self.trace_tracker
    @@trace_tracker
  end

  def a
    aa
  end

  private def aa
    7
  end

  def a(x)
    7 * x
  end

  def b(x)
    123
  end

  def c(this : Int32,
        that : String)
    {this => that}
  end

  def nop
    :nop
  end

  def traced_nop
    :traced_nop
  end

  def self.a
    77
  end

  def self.b(n)
    loop do
      num = rand()
      break num if num > n
    end
  end

  def none
    nil
  end

  def also_none
    none
  end

  def one
    1
  end

  def also_one
    one
  end

  def two
    2
  end

  def also_two
    two
  end

  def three
    3
  end

  def also_three
    three
  end

  def four
    4
  end

  def also_four
    four
  end

  def five
    5
  end

  def also_five
    five
  end

  add_method_hooks(
    "a",
    ->() {
      start_time = Time.monotonic
      @@log[{__trace_method_identifier__, __trace_method_call_counter__}] << start_time
      begin
        previous_def
      ensure
        finish_time = Time.monotonic
        @@log[{__trace_method_identifier__, __trace_method_call_counter__}] << finish_time
      end
    }
  )

  def self.flag(method, phase, identifier, counter, caller)
    @@log[{identifier, counter}] << Time.monotonic
  end

  def flag(method, phase, identifier, counter, caller)
    self.class.flag(method, phase, identifier, counter, caller)
  end

  def nothingburger(method, phase, identifier, counter, caller)
  end

  trace(
    "c",
    ->() {@@log[{__trace_method_identifier__, __trace_method_call_counter__}] << Time.monotonic}
  )

  trace(
    "self.a",
    "flag"
  )

  trace(
    "b",
    "flag"
  )

  trace(
    "TestObj.b",
    "flag"
  )

  trace(
    "traced_nop",
    "nothingburger"
  )

  trace(
    "none",
    ->() {@@trace_tracker["none"] = ""}
  )

  trace("also_none") {@@trace_tracker["also_none"] = ""}

  trace(
    "one",
    ->(method_name : String) {@@trace_tracker["one"] = method_name}
  )

  trace("also_one") {|method_name| @@trace_tracker["also_one"] = method_name}

  trace(
    "two",
    ->(method_name : String, phase : Symbol) {@@trace_tracker["two"] = "#{method_name}|#{phase}"}
  )

  trace("also_two") {|method_name, phase| @@trace_tracker["also_two"] = "#{method_name}|#{phase}"}

  trace(
    "three",
    ->(method_name : String, phase : Symbol, identifier : String) {@@trace_tracker["three"] = "#{method_name}|#{phase}|#{identifier}"}
  )

  trace("also_three") {|method_name, phase, identifier| @@trace_tracker["also_three"] = "#{method_name}|#{phase}|#{identifier}"}

  trace(
    "four",
    ->(method_name : String, phase : Symbol, identifier : String, counter : UInt128) {@@trace_tracker["four"] = "#{method_name}|#{phase}|#{identifier}|#{counter}"}
  )

  trace("also_four") {|method_name, phase, identifier, counter| @@trace_tracker["also_four"] = "#{method_name}|#{phase}|#{identifier}|#{counter}"}

  trace(
    "five",
    ->(method_name : String, phase : Symbol, identifier : String, counter : UInt128, caller : TestObj) {@@trace_tracker["five"] = "#{method_name}|#{phase}|#{identifier}|#{counter}|#{caller}"}
  )

  trace("also_five") {|method_name, phase, identifier, counter, caller| @@trace_tracker["also_five"] = "#{method_name}|#{phase}|#{identifier}|#{counter}|#{caller}"}
end
