require "./tracer/version"

module Tracer
  METHOD_COUNTER      = [0_u128]
  TRACED_METHOD_NAMES = {} of Tuple(String, String) => Bool

  macro finished
    {%
      traced_methods = [] of Nil
      traced_methods_by_receiver = {} of Nil => Array(String)
    %}
    {% for name_pair in TRACED_METHOD_NAMES.keys %}
    {%
      method_name, receiver_name = name_pair
      if receiver_name == "self"
        receiver = @type.class
      else
        receiver = nil
        search_paths = [@top_level]
        search_paths << @type.class unless receiver_name[0..1] == "::"

        search_paths.each do |search_path|
          unless receiver
            found_the_receiver = true
            parts = receiver_name.split("::")
            parts.each do |part|
              if found_the_receiver
                constant_id = search_path.constants.find { |c| c.id == part }
                if !constant_id
                  found_the_receiver = false
                else
                  search_path = search_path.constant(constant_id)
                  found_the_receiver = false if search_path.nil?
                end
              end
            end

            if found_the_receiver
              receiver = search_path
            end
          end
        end

        traced_methods << [method_name, receiver]
        if !traced_methods_by_receiver[receiver]
          traced_methods_by_receiver[receiver] = [] of String
        end
        traced_methods_by_receiver[receiver] << method_name
      end
    %}
    {% end %}
    {% if traced_methods.size > 0 %}
    TRACED_METHODS = {
      {% for pair in traced_methods %}
      { {{ pair[0] }}, {{ pair[1].id }} },
      {% end %}
    }

    TRACED_METHODS_BY_RECEIVER = {
      {% for receiver, methods in traced_methods_by_receiver %}
      {{ receiver.id }} => {
        {% for method in methods %}
        {{ method }},
        {% end %}
      },
      {% end %}
    }
    {% else %}
    TRACED_METHODS = Tuple.new
    TRACED_METHODS_BY_RECEIVER = {} of Nil => Nil
    {% end %}
    {% debug if flag? :DEBUG %}
  end
end

# This annotation will be used to support annotation based trace management.
# This feature hasn't been built yet.
annotation Trace
end

macro add_method_hooks(method_name, block_def = nil, &block)
  {%
    if method_name.includes?(".")
      receiver_name, method_name = method_name.split(".")

      if receiver_name == "self"
        receiver = @type.class
      else
        receiver = nil
        search_paths = [@top_level]
        search_paths << @type.class unless receiver_name[0..1] == "::"

        search_paths.each do |search_path|
          unless receiver
            found_the_receiver = true
            parts = receiver_name.split("::")
            parts.each do |part|
              if found_the_receiver
                constant_id = search_path.constants.find { |c| c.id == part }
                if !constant_id
                  found_the_receiver = false
                else
                  search_path = search_path.constant(constant_id)
                  found_the_receiver = false if search_path.nil?
                end
              end
            end

            if found_the_receiver
              receiver = search_path.class
            end
          end
        end
      end
    else
      receiver = @type
    end
  %}
  {% methods = receiver ? receiver.methods.select { |m| m.name.id == method_name } : [] of Nil %}
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

    trace_enabled = true # TODO: Implement a dynamic method to enable or disable tracing.
    trace_method_receiver = "#{receiver.id.gsub(/\.class/, "").gsub(/:Module/, "")}".id
    trace_method_identifier = "#{trace_method_receiver}__#{method_name.id}__#{method.line_number.id}X#{method.column_number.id}"
  %}
  {{ method.visibility.id == "public" ? "".id : method.visibility.id }} def {{ receiver == @type ? "".id : "#{receiver.id.gsub(/\.class/, "").gsub(/:Module/, "")}.".id }}{{ method.name.id }}{{ !method_args.empty? ? "(".id : "".id }}{{ method_args.join(", ").id }}{{ !method_args.empty? ? ")".id : "".id }}{{ method.return_type.id != "" ? " : #{method.return_type.id}".id : "".id }}
    # {{ receiver.id }}
    __trace_method_receiver__ = {{ trace_method_receiver }}
    __trace_method_call_counter__ = Tracer::METHOD_COUNTER[0]
    Tracer::METHOD_COUNTER[0] = Tracer::METHOD_COUNTER[0] &+ 1
    {% Tracer::TRACED_METHOD_NAMES[{method_name, trace_method_receiver.id.stringify}] = true %}
    __trace_method_name__ = {{ method_name }}
    __trace_method_identifier__ = {{ trace_method_identifier }}

    {{ block.body.id.gsub(/previous_def\(\)/, "previous_def").id }} # TODO: Better way than a regexp?
  end
  {% end %}
  {% debug if flag? :DEBUG %}
end

macro trace(method_name, callback, block_def = nil)
  add_method_hooks(
    {{ method_name }},
    {{ block_def }}) do
      {% if callback.is_a?(Block) || callback.is_a?(ProcLiteral) %}
      {%
        pre_args = [] of Nil
        post_args = [] of Nil
        callback_arity = callback.args.size

        if callback_arity > 0
          pre_args << method_name.stringify
          post_args << method_name.stringify
        end
        if callback_arity > 1
          pre_args << ":before".id
          post_args << ":after".id
        end
        if callback_arity > 2
          pre_args << "__trace_method_identifier__".id
          post_args << "__trace_method_identifier__".id
        end
        if callback_arity > 3
          pre_args << "__trace_method_call_counter__".id
          post_args << "__trace_method_call_counter__".id
        end
        if callback_arity > 4
          pre_args << "self".id
          post_args << "self".id
        end
      %}
      begin
        {{ callback.id }}.call({{ pre_args.join(", ").id }})
        {% if !(callback.id.stringify =~ /previous_def/) %}
        previous_def
        {% end %}
      ensure
        {% if !(callback.id.stringify =~ /previous_def/) %}
        {{ callback.id }}.call({{ post_args.join(", ").id }})
        {% end %}
      end
      {% else %}
      begin
        {{ callback.id }}({{ method_name }}, :before, __trace_method_identifier__, __trace_method_call_counter__, self)
        previous_def
      ensure
        {{ callback.id }}({{ method_name }}, :after, __trace_method_identifier__, __trace_method_call_counter__, self)
      end
      {% end %}
  end
  {% debug if flag? :DEBUG %}
end

macro trace(method_name, block_def = nil, &block)
  add_method_hooks(
    {{ method_name }},
    {{ block_def }}) do
      begin
        __trace_phase__ = :before
        {{ block.body.id }}
        {% if !(block.id.stringify =~ /previous_def/) %}
        previous_def
        {% end %}
      ensure
        __trace_phase__ = :after
        {% if !(block.id.stringify =~ /previous_def/) %}
        {{ block.body.id }}
        {% end %}
      end
  end
  {% debug if flag? :DEBUG %}
end
