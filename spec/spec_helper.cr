require "spec"
require "../src/tracer"

class TestObj
  include Tracer

  @@log : Hash(Tuple(String, UInt128), Array(Time::Span)) = Hash(Tuple(String, UInt128), Array(Time::Span)).new {|h,k| h[k] = [] of Time::Span}

  def self.log
    @@log
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

  add_method_hooks(
    "a",
    ->() {
      start_time = Time.monotonic
      @@log[{__trace_method_identifier__, __trace_method_call_counter__}] << start_time
      puts "start #{__trace_method_name__} as #{__trace_method_identifier__}"
      begin
        previous_def
      ensure
        finish_time = Time.monotonic
        puts "end runtime #{finish_time - start_time}"
        @@log[{__trace_method_identifier__, __trace_method_call_counter__}] << finish_time
      end
    }
  )

  def self.flag(zelf, method, phase, identifier, counter)
    puts "klass: #{zelf.class}\nmethod: #{method}\nphase: #{phase}\nidentifier: #{identifier}"
    @@log[{identifier, counter}] << Time.monotonic
  end

  def flag(zelf, method, phase, identifier, counter)
    self.class.flag(zelf, method, phase, identifier, counter)
  end

  def nothingburger(caller, method, phase, identifier, counter)
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
end

class ExternalTraceManager
  @@log : Hash(Tuple(String, UInt128), Array(Time::Span)) = Hash(Tuple(String, UInt128), Array(Time::Span)).new {|h,k| h[k] = [] of Time::Span}

  def self.log(caller, method, phase, identifier, counter)
    @@log[{identifier, counter}] << Time.monotonic
  end

  def self.log
    @@log
  end
end