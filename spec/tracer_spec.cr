require "./spec_helper"

describe Tracer do
  it "works" do
    obj = TestObj.new

    obj.a.should eq 7
    obj.a(2).should eq 14
    obj.b(456).should eq 123
    obj.c(123, "this").should eq ({123 => "this"})
    TestObj.a.should eq 77

    pp TestObj.log
  end
end
