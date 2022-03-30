module TestModule
  def self.foo
    7
  end

  trace(
    "self.foo",
    ->{ ExternalTraceManager.log(__trace_method_receiver__, __trace_method_identifier__, __trace_method_call_counter__) }
  )
end
