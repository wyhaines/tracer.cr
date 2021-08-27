module Tracer
  VERSION = "0.1.0"

  # This annotation can be used to turn on, to configure call tracing for a given method.
  # The mode of trace will either be detail or summary, and it defaults to summary.
  # It is specified with a key of "mode", and a value of either :detail or :summary.
  # If the "inject" key is present, it should be either a proc or a method 
  annotation Trace
  end

  macro hook_method_name
    "#\{method_name}"
  end

  macro add_method_hooks(method_name, method_body = "", supplemental_arguments = nil)
    {% methods = @type.methods.select {|m| m.name.id == method_name} %}
    {% for method in methods %}
    {{ method.stringify.split("\n")[0].id }}
      method_name = {{ method_name }}
      {{ method_body.is_a?(StringLiteral) ? method_body.id : method_body.body.id.gsub(/previous_def\(\)/,"previous_def").id }}
    end
    {% end %}
  end

  macro add_method_tracer(method_name, callback)
    add_method_hooks(
      {{ method_name }},
      ->() {
        {% if callback.is_a?(Block) || callback.is_a?(ProcLiteral) %}
        {{ callback.id }}.call(self, {{ method_name }}, "pre")
        previous_def
        {{ callback.id }}.call(self, {{ method_name }}, "post")
        {% else %}
        {{ callback.id }}(self, {{ method_name }}, "pre")
        previous_def
        {{ callback.id }}(self, {{ method_name }}, "post")
        {% end %}
      }
    )
  end

  macro included
  end
end