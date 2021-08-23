require "./spec_helper"

describe CallTrace do
  it "works" do
    obj = TestObj.new

    (rand(10) + 2).times { f.a }
    (rand(6) + 4).times { f.b(123) }
    f.c(123, "this")
  end
end
