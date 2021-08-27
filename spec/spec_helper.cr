require "spec"
require "../src/tracer"

class TestObj
  include Tracer

  @[Trace(enabled: true)]
  private def a
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

  add_method_hooks(
    "a",
    ->() { 
      start_time = Time.monotonic
      puts "start #{hook_method_name}"
      previous_def
      puts "end runtime #{Time.monotonic - start_time}"
    }
  )

  def flag(zelf, method, phase)
    puts "klass: #{zelf.class}\nmethod: #{method}\nphase: #{phase}"
  end
  
  add_method_tracer(
    "c",
    ->(zelf : self.class, method : String, phase : String) {puts ">> klass: #{zelf.class}\nmethod: #{method}\nphase: #{phase}"}
  )

  add_method_tracer(
    "b",
    "flag"
  )

end
