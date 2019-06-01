# Datadog Annotation

[![Gem Version](https://badge.fury.io/rb/ddtrace-annotation.svg)](https://badge.fury.io/rb/ddtrace-annotation)
[![Build Status](https://travis-ci.com/downgba/ddtrace-annotation.svg?branch=master)](https://travis-ci.com/downgba/ddtrace-annotation)
[![Maintainability](https://api.codeclimate.com/v1/badges/b48b7c15e8925e6f2c6d/maintainability)](https://codeclimate.com/github/downgba/ddtrace-annotation/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/b48b7c15e8925e6f2c6d/test_coverage)](https://codeclimate.com/github/downgba/ddtrace-annotation/test_coverage)

Datadog Annotation allows you to annotate methods to be traced by Datadog Tracing Ruby Client.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ddtrace-annotation'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ddtrace-annotation

## Usage

```ruby
class Test
  include Datadog::Annotation
  
  __trace(
    method: :method_to_be_traced,
    service: "service-name"
  )
  def method_to_be_traced; end
end
```
`__trace` accepts two more parameters, both of them are optionals:   
 - resource: action to be traced, by default its value is `class_name#method_name`. This argument accepts a `String` or a `Proc`. So if you want to use some information that you receive by parameter you can use a proc.   
    Ex:    
    ```ruby
    class Test
      include Datadog::Annotation

      __trace(
        method: :method_to_be_traced,
        service: "service-name",
        resource: Proc.new { |_, type| "MyClass##{type}"}
      )
      def method_to_be_traced(name, type); end
    end
    ```

    
 - metadata: allows you to set tags into the current trace. This argument accepts a `Proc`, it passes to the given proc the method arguments, the result of the method and the span.   
    - args[Hash<Symbol, Object>].   
    - result[Object].   
    - span[Datadog::Span].   
    
    Ex:   
    ```ruby
    class Test
      include Datadog::Annotation

      __trace(
        method: :method_to_be_traced,
        service: "service-name",
        metadata: Proc.new do |args, result, span|
          span.set_tag("name", args[:name])
          span.set_tag("result", result)
        end
      )
      def method_to_be_traced(name, type); end
    end
    ```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/downgba/ddtrace-annotation.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
