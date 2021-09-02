require "spec"
require "../src/tracer"

class TestObj
  include Tracer

  @@log : Hash(Tuple(String, UInt128), Array(Time::Span)) = Hash(Tuple(String, UInt128), Array(Time::Span)).new {|h,k| h[k] = [] of Time::Span}

  def self.log
    @@log
  end

  @[Trace(enabled: true)]

  def a
    aa
  end

  private def aa
    puts "priv"
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

  def self.a
    77
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

  def flag(zelf, method, phase, identifier, counter)
    puts "klass: #{zelf.class}\nmethod: #{method}\nphase: #{phase}\nidentifier: #{identifier}"
    @@log[{identifier, counter}] << Time.monotonic
  end
  
  add_method_tracer(
    "c",
    ->() {@@log[{__trace_method_identifier__, __trace_method_call_counter__}] << Time.monotonic}
  )

  add_method_tracer(
    "self.a",
    "flag"
  )

  add_method_tracer(
    "b",
    "flag"
  )
end
