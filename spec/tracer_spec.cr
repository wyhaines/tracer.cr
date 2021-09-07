require "./spec_helper"
require "benchmark"

describe Tracer do
  it "works" do
    obj = TestObj.new

    obj.a.should eq 7
    obj.a(2).should eq 14
    obj.b(456).should eq 123
    obj.c(123, "this").should eq ({123 => "this"})
    TestObj.a.should eq 77
    (TestObj.b(0.99) > 0.99).should be_true

    pp TestObj.log

    Benchmark.ips do |ips|
      ips.report("no tracing") {obj.nop}
      ips.report("tracing") {obj.traced_nop}
    end
  end
end
