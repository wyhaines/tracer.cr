require "./spec_helper"

describe Tracer do
  it "works" do
    obj = TestObj.new

    (rand(10) + 2).times { obj.a }
    (rand(6) + 4).times { obj.b(123) }
    obj.c(123, "this")
  end
end
