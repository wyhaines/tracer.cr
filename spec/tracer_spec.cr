require "./spec_helper"
require "benchmark"

describe Tracer do
  it "logs a call to a simple method with no arguments" do
    obj = TestObj.new
    obj.a.should eq 7

    TestObj.log.select { |k, _| k[0] =~ /TestObj__a/ }.should_not be_empty
  end

  it "logs a call to a simple overloaded method that takes a simple argument" do
    obj = TestObj.new
    obj.a(2).should eq 14

    TestObj.log.select { |k, _| k[0] =~ /TestObj__a/ }.should_not be_empty
  end

  it "logs a call to a simple method that takes a simple argument" do
    obj = TestObj.new
    obj.b(456).should eq 123

    TestObj.log.select { |k, _| k[0] =~ /TestObj__b/ }.should_not be_empty
  end

  it "logs a call to a simple method that takes multiple arguments" do
    obj = TestObj.new
    obj.c(123, "this").should eq({123 => "this"})

    TestObj.log.select { |k, _| k[0] =~ /TestObj__c/ }.should_not be_empty
  end

  it "logs a call to a class method" do
    TestObj.a.should eq 77

    TestObj.log.select { |k, _| k[0] =~ /TestObj__a/ }.should_not be_empty
  end

  it "logs a call to a class method that takes an argument" do
    obj = TestObj.new
    (TestObj.b(0.99) > 0.99).should be_true

    TestObj.log.select { |k, _| k[0] =~ /TestObj__b/ }.should_not be_empty
  end

  it "logs a call to a class method declared on a module instead of a class" do
    TestModule.foo.should eq 7

    ExternalTraceManager.log.count { |k, _| k[0] == "TestModule" }.should eq 1
  end

  it "works with an instance method in a struct" do
    obj = TestStruct.new("I am a test struct")

    obj.value.should eq "I am a test struct"
    obj.framed_value.should eq "|I am a test struct|"

    ExternalTraceManager.log.count { |k, _| k[0] == "TestStruct" }.should eq 1
  end

  it "works with a class method in a struct" do
    TestStruct.random.class.should eq TestStruct
    TestStruct.random.value.size.should eq 22

    ExternalTraceManager.log.count { |k, _| k[0] == "TestStruct" && k[1] =~ /random__/ }.should eq 2
  end

  it "proc style callbacks with no arguments work as expected" do
    obj = TestObj.new

    obj.none.should be_nil
    TestObj.trace_tracker.keys.includes?("none").should be_true
  end

  it "block style callbacks with no arguments work as expected" do
    obj = TestObj.new

    obj.also_none.should be_nil
    TestObj.trace_tracker.keys.includes?("also_none").should be_true
  end

  it "proc style callbacks with one argument work as expected" do
    obj = TestObj.new

    obj.one.should eq 1
    TestObj.trace_tracker.keys.includes?("one").should be_true
    TestObj.trace_tracker["one"].should eq "one"
  end

  it "block style callbacks with one argument work as expected" do
    obj = TestObj.new

    obj.also_one.should eq 1
    TestObj.trace_tracker.keys.includes?("also_one").should be_true
    TestObj.trace_tracker["also_one"].should eq "also_one"
  end

  it "proc style callbacks with two arguments work as expected" do
    obj = TestObj.new

    obj.two.should eq 2
    TestObj.trace_tracker.keys.includes?("two").should be_true
    TestObj.trace_tracker["two"].should eq "two|after"
  end

  it "block style callbacks with two arguments work as expected" do
    obj = TestObj.new

    obj.also_two.should eq 2
    TestObj.trace_tracker.keys.includes?("also_two").should be_true
    TestObj.trace_tracker["also_two"].should eq "also_two|after"
  end

  it "proc style callbacks with three arguments work as expected" do
    obj = TestObj.new

    obj.three.should eq 3
    TestObj.trace_tracker.keys.includes?("three").should be_true
    TestObj.trace_tracker["three"].should start_with("three|after|TestObj__three")
  end

  it "block style callbacks with three arguments work as expected" do
    obj = TestObj.new

    obj.also_three.should eq 3
    TestObj.trace_tracker.keys.includes?("also_three").should be_true
    TestObj.trace_tracker["also_three"].should start_with("also_three|after|TestObj__also_three")
  end

  it "proc style callbacks with four arguments work as expected" do
    obj = TestObj.new

    obj.four.should eq 4
    TestObj.trace_tracker.keys.includes?("four").should be_true
    TestObj.trace_tracker["four"].should start_with("four|after|TestObj__four")
    TestObj.trace_tracker["four"].should match(/four\|after\|TestObj__four__\d+X\d+\|\d+/)
  end

  it "block style callbacks with four arguments work as expected" do
    obj = TestObj.new

    obj.also_four.should eq 4
    TestObj.trace_tracker.keys.includes?("also_four").should be_true
    TestObj.trace_tracker["also_four"].should start_with("also_four|after|TestObj__also_four")
    TestObj.trace_tracker["also_four"].should match(/also_four\|after\|TestObj__also_four__\d+X\d+\|\d+/)
  end

  it "proc style callbacks with five arguments work as expected" do
    obj = TestObj.new

    obj.five.should eq 5
    TestObj.trace_tracker.keys.includes?("five").should be_true
    TestObj.trace_tracker["five"].should start_with("five|after|TestObj__five")
    TestObj.trace_tracker["five"].should match(/five\|after\|TestObj__five__\d+X\d+\|\d+\|#<TestObj/)
  end

  it "block style callbacks with five arguments work as expected" do
    obj = TestObj.new

    obj.also_five.should eq 5
    TestObj.trace_tracker.keys.includes?("also_five").should be_true
    TestObj.trace_tracker["also_five"].should start_with("also_five|after|TestObj__also_five")
    TestObj.trace_tracker["also_five"].should match(/also_five\|after\|TestObj__also_five__\d+X\d+\|\d+\|#<TestObj/)
  end

  it "has access to an Tuple of actual method names and receiver classes" do
    Tracer::TRACED_METHODS.size.should eq 19
    Tracer::TRACED_METHODS.includes?({"a", TestObj}).should be_true
    Tracer::TRACED_METHODS.includes?({"b", TestObj}).should be_true
    Tracer::TRACED_METHODS.includes?({"random", TestStruct}).should be_true
    pp Tracer::TRACED_METHODS
  end

  it "has access to a NamedTuple of Receivers and the methods that have had tracers applied" do
    Tracer::TRACED_METHODS_BY_RECEIVER.size.should eq 3
    pp Tracer::TRACED_METHODS_BY_RECEIVER
  end

  # The benchmark only runs when compiled in release mode.
  {% if flag? :release %}
    it "benchmarking works, and the absolute cost of tracing is negligible" do
      obj = TestObj.new

      puts "\nSimple Benchmarking:"
      Benchmark.ips do |ips|
        ips.report("no tracing") { obj.nop }
        ips.report("tracing") { obj.traced_nop }
      end
    end
  {% end %}
end
