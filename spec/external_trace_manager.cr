class ExternalTraceManager
  @@log : Hash(Tuple(String, String, UInt128), Array(Time::Span)) = Hash(Tuple(String, String, UInt128), Array(Time::Span)).new {|h,k| h[k] = [] of Time::Span}

  def self.log(receiver, identifier, counter)
    @@log[{receiver.name, identifier, counter}] << Time.monotonic
  end

  def self.log
    @@log
  end
end