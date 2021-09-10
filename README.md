# Tracer.cr

*WARNING: This code is super-alpha. Details about its interface are likely to change.*
  
Tracer.cr provides a facility for attaching tracing code to methods in Crystal code.

This library is pretty low-level. It provides a simple interface to use to attach functionality to existing code, but doesn't provide any higher level functionality around that. It is intended to be a building block for constructing that higher level functionality - debugging, performance monitoring, or execution auditing, for example.

It works through a combination of macros, and leveraging the `previous_def` capability to invoke the previously defined version of a library.

The current version nominally works, but it is missing some key features that are on the short term roadmap:

1. Add support for the `Trace` annotation so that tracing can be managed via annotations.
2. Add support for dynamically disabling trace code. It would be really nifty if we could do object inheritance chain manipulation in Crystal like one can in Ruby, when leveraging `prepend` for this sort of stuff, but Crystal's compiled nature doesn't make it dynamic in that way, so the plan is to enable dynamic disabling of trace code through a lookup table and simple `if` statements. It will have some impact on performance, even when the trace code is disabled, but the impact should be extremely small.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     call_trace:
       github: wyhaines/tracer.cr
   ```

2. Run `shards install`

## Usage

```crystal
require "tracer"
```

To use the tracer, require the shard. This will define macros to support all other tracing tasks.

The main macro that is used to establish tracing functions is `trace`. It takes two required arguments, and one optional argument.

`trace(METHOD_NAME, CALLBACK, BLOCK_DEFINITION)`

The `METHOD_NAME` should be a `String` that is the name of the method that is being traced. The `CALLBACK` can be either a string specifying a method to call both before and after `METHOD_NAME` is called, or a `Proc` that will be invoked both before and after `METHOD_NAME` is called.

A callback method is expected to take five arguments:

```crystal
def callback(caller, method_name, phase, method_identifier, method_counter)
```

* *method_name*: This will contain the name of the method that is being traced.
* *phase*: This will contain the phase of the tracing. This will be one of `:before` or `:after`, depending on whether the callback is being invoked before the method being traced, or after it.
* *method_identifier*: This will contain the identifier of the method being traced. This identifier is a combination of the class/module/struct name, and the line/column of the file where the method definition starts. For example: `TestObject__my_method__11X3`
* *method_counter*: This contains a monotonically increasing number which is a simple count of methods. Each method that is traced increments this counter by one. The count is an unsigned 128-bit integer.
* *caller*: This will contain `self`, the object that the method is running in.

```crystal
trace("my_method", "my_callback")
```

```crystal
trace("my_method", ->() {puts "Doing tracing stuff"})
```

```crystal
trace("my_method", ->(method_name : String) {puts "Tracing #{method_name}"})
```

## Development

If you want to help with the development, email me, and fork the repo. Work on your changes in a branch out of your own repo, and when it is ready (with documentation and specs), send me a pull request telling me what you have done, why you have done it, and what you have done to make sure that it works as expected.

## Contributing

1. Fork it (<https://github.com/wyhaines/tracer.cr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Kirk Haines](https://github.com/wyhaines) - creator and maintainer
