# Here is how I think that this should work:
#
# 1. Call tracing can be added to any class by including the module into the class.
# 2. Call tracing can be declared and injected into a class/module/struct imperatively.
# 3. Call tracing can be turned on for all of the methods in a class, or for only a subset of methods in the class.
# 4. Call tracing can generate either a summary log of activity or a detailed log of activity.
# 5. The type of tracing to generate is configurable on a per method basis.
module CallTrace
  VERSION = "0.1.0"

  # This annotation can be used to turn on, to configure call tracing for a given method.
  # The mode of trace will either be detail or summary, and it defaults to summary.
  # It is specified with a key of "mode", and a value of either :detail or :summary.
  # If the "inject" key is present, it should be either a proc or a method 
  annotation CallTrace
  end

  @call_trace_log : Hash(
    String,
    Array(NamedTuple(timestamp: Time, caller: String))
  ) = Hash(
    String,
    Array(NamedTuple(timestamp: Time, caller: String))).new do |h, k|
       h[k] = [] of NamedTuple(timestamp: Time, caller: String)
    end

  @call_trace_summary : Hash(String, Hash(String, Int64)) = Hash(String, Hash(String, Int64)).new

  def calltrace_add_trace(meth, callstack, mode = :summary)
    @call_trace_log[meth] << {timestamp: Time.local, caller: callstack.printable_backtrace[1]}
  end

  macro calltrace_enable(target)
  end

  macro included
    # Check if CallTrace annotation exists on the type. If it does, then its values are defaults for all methods in the type.
    macro method_added(method)
      \{%
        trace_enabled = false
        trace_mode = :summary

        if ann = @type.annotation(CallTrace)
          trace_enabled = ann[:enabled] if ann[:enabled]
          trace_mode = ann[:mode] if ann[:mode]
        end

        if ann = method.annotation(CallTrace)
          trace_enabled = ann[:enabled] if ann[:enabled]
          trace_mode = ann[:mode] if ann[:mode]
        end
      %}
      \{% if trace_enabled %}
        \{{ method.stringify.split("\n")[0].id }}
        self.calltrace_add_trace(\{{ method.name.stringify }}, Exception::CallStack.new, \{{ trace_mode }})
        \{{ method.body.id }}
        \{{ "end".id }}
      \{% end %}
    end
  end
end
