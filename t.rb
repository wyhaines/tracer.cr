require "benchmark"

class Foo
  def bar
    7
  end
end

obj = Foo.new

Benchmark.bm do |bm|
  bm.report("direct") {30000000.times {obj.bar}}
  bm.report("send") {30000000.times {obj.send(:bar)}}
end
