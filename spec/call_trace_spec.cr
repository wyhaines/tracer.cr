require "./spec_helper"

describe CallTrace do
  it "works" do
    obj = TestObj.new

    (rand(10) + 2).times { obj.a }
    (rand(6) + 4).times { obj.b(123) }
    obj.c(123, "this")

    pp obj
  end
end
