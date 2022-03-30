struct TestStruct
  property value

  def initialize(@value : String)
  end

  def framed_value
    "|#{value}|"
  end

  def self.random
    new(Random.new.urlsafe_base64)
  end
end

struct TestStruct
  trace(
    "framed_value",
    ->{ ExternalTraceManager.log(__trace_method_receiver__, __trace_method_identifier__, __trace_method_call_counter__) }
  )
end

trace(
  "TestStruct.random",
  ->{ ExternalTraceManager.log(__trace_method_receiver__, __trace_method_identifier__, __trace_method_call_counter__) }
)
