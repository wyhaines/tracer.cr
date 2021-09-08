require "./spec_helper"
require "benchmark"

describe Tracer do
  it "logs a call to a simple method with no arguments" do
    obj = TestObj.new
    obj.a.should eq 7
  end

  it "logs a call to a simple overloaded method that takes a simple argument" do
    obj = TestObj.new

    obj.a(2).should eq 14
  end

  it "logs a call to a simple method that takes a simple argument" do
    obj = TestObj.new

    obj.b(456).should eq 123
  end

  it "logs a call to a simple method that takes multiple arguments" do
    obj = TestObj.new

    obj.c(123, "this").should eq ({123 => "this"})
  end

  it "logs a call to a class method" do
    obj = TestObj.new

    TestObj.a.should eq 77
  end

  it "logs a call to a class method that takes an argument" do
    obj = TestObj.new

    (TestObj.b(0.99) > 0.99).should be_true
  end

  it "logs a call to a class method declared on a module instead of a class" do
    obj = TestObj.new

  end

  it "benchmarking works, and the absolute cost of tracing is negligible" do
    obj = TestObj.new

    Benchmark.ips do |ips|
      ips.report("no tracing") {obj.nop}
      ips.report("tracing") {obj.traced_nop}
    end
  end
end
