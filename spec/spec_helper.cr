require "spec"
require "../src/call_trace"

class TestObj
  include CallTrace

  @[CallTrace(enabled: true)]
  def a
    7
  end

  def b(x)
    123
  end

  def c(this : Int32,
        that : String)
    {this => that}
  end

  def finalize
    @call_trace_log.each do |key, value|
      puts "#{key}:"
      value.each do |ntup|
        puts "   #{ntup[:caller].chomp} -> #{ntup[:timestamp]}"
      end
    end
  end
end
