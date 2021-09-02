module Tracer
  VERSION = "0.1.0"

  METHOD_COUNTER = [0_u128]

  # This annotation can be used to turn on, to configure call tracing for a given method.
  # The mode of trace will either be detail or summary, and it defaults to summary.
  # It is specified with a key of "mode", and a value of either :detail or :summary.
  # If the "inject" key is present, it should be either a proc or a method 
  annotation Trace
  end

  macro add_method_hooks(method_name, method_body = "", block_def = nil)
    {% methods = @type.methods.select {|m| m.name.id == method_name} %}
    {% for method in methods %}
    {%
      method_args = method.args
      if method.accepts_block? && method.block_arg
        block_arg = "&#{method.block_arg.id}".id
      else
        block_arg = nil
      end

      if block_arg
        method_args << block_arg
      end

      if block_def
        method_args << block_def
      end

      create_trace_annotation = !method.annotation(Trace)
      if create_trace_annotation
        trace_enabled = true
        trace_method_identifier = "#{method_name.id}__#{method.line_number.id}X#{method.column_number.id}"
      end
    %}
    {{ method.visibility.id == "public" ? "".id : method.visibility.id }} def {{ method.name.id }}{{ !method_args.empty? ? "(".id : "".id }}{{ method_args.join(", ").id }}{{ !method_args.empty? ? ")".id : "".id }}{{ method.return_type.id != "" ? " : #{method.return_type.id}".id : "".id }}
      __trace_method_call_counter__ = METHOD_COUNTER[0]
      METHOD_COUNTER[0] = METHOD_COUNTER[0] &+ 1  
      __trace_method_name__ = {{ method_name }}
      __trace_method_identifier__ = {{ trace_method_identifier }}
      
      {{ method_body.is_a?(StringLiteral) ? method_body.id : method_body.body.id.gsub(/previous_def\(\)/,"previous_def").id }}
    end
    {% end %}
    {% debug %}
  end

  macro add_method_tracer(method_name, callback, block_def = nil)
    add_method_hooks(
      {{ method_name }},
      ->() {
        {% if callback.is_a?(Block) || callback.is_a?(ProcLiteral) %}
        {%
          pre_args = [] of Nil
          post_args = [] of Nil
          callback_arity = callback.args.size

          if callback_arity > 0
            pre_args << "self".id
            post_args << "self".id
          end
          if callback_arity > 1
            pre_args << method_name.stringify
            post_args << method_name.stringify
          end
          if callback_arity > 2
            pre_args << "pre".stringify
            post_args << "post".stringify
          end
          if callback_arity > 3
            pre_args << "__trace_method_identifier__".id
            post_args << "__trace_method_identifier__".id
          end
          if callback_arity > 4
            pre_args << "__trace_method_call_counter__".id
            post_args << "__trace_method_call_counter__".id
          end
        %}
        begin
          {{ callback.id }}.call({{ pre_args.join(", ").id }})
          previous_def
        ensure
          {{ callback.id }}.call({{ post_args.join(", ").id }})
        end
        {% else %}
        begin
          {{ callback.id }}(self, {{ method_name }}, "pre", __trace_method_identifier__, __trace_method_call_counter__)
          previous_def
        ensure
          {{ callback.id }}(self, {{ method_name }}, "post", __trace_method_identifier__, __trace_method_call_counter__)
        end
        {% end %}
      },
      {{ block_def }}
    )
    {% debug %}
  end

  macro included
  end
end