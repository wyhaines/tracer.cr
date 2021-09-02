class A
end

class A::B
end

{%
  puts "-----"
  parts = "A::B".split("::")
  level = @top_level
  parts.each do |part|
    puts "level: #{level}\npart: #{part}"
    level = level.constants.find {|c| c.id == part}.resolve
    
  end

  pp level
%}
