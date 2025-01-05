![regent_light](https://github.com/user-attachments/assets/62564dac-b8d7-4dc0-9b63-64c6841b5872)

<div align="center">

# Regent

[![Gem Version](https://badge.fury.io/rb/regent.svg)](https://badge.fury.io/rb/regent)
[![Build](https://github.com/alchaplinsky/regent/actions/workflows/main.yml/badge.svg)](https://github.com/alchaplinsky/regent/actions/workflows/main.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

</div>

**Regent** is a small and elegant Ruby framework for building AI agents that can think, reason, and take actions through tools. It provides a clean, intuitive interface for creating agents that can solve complex problems by breaking them down into logical steps.

> [!WARNING]
> Regent is currently an experiment intended to explore patterns for building easily traceable and debuggable AI agents of different architectures. It is not yet intended to be used in production and is currently in development.

## Key Features

- **ReAct Pattern Implementation**: Agents follow the Reasoning-Action pattern, making decisions through a clear thought process before taking actions
- **Multi-LLM Support**: Seamlessly works with:
  - OpenAI (GPT models)
  - Anthropic (Claude models)
  - Google (Gemini models)
- **Extensible Tool System**: Create custom tools that agents can use to interact with external services, APIs, or perform specific tasks
- **Built-in Tracing**: Every agent interaction is traced and can be replayed, making debugging and monitoring straightforward
- **Clean Ruby Interface**: Designed to feel natural to Ruby developers while maintaining powerful capabilities

## Showcase

A basic Regnt Agent extended with a `price_tool` that allows for retrieving cryptocurrency prices from coingecko.com.

![Screen_gif](https://github.com/user-attachments/assets/63c8c923-0c1e-48db-99f6-33758411623f)

## Quick Start

```bash
gem install regent
```

or add regent to the Gemfile:

```ruby
gem 'regent'
```

and run

```bash
bundle install
```

## Usage

Create your first agent:

```ruby
# Initialize the LLM
model = Regent::LLM.new("gpt-4o")

# Create a custom tool
class WeatherTool < Regent::Tool
  def call(location)
    # Implement weather lookup logic
    "Currently 72°F and sunny in #{location}"
  end
end

# Create and configure the agent
agent = Regent::Agent.new(
  "You are a helpful weather assistant",
  model: model,
  tools: [WeatherTool.new(
    name: "weather_tool",
    description: "Get current weather for a location"
  )]
)

# Execute a query
agent.run("What's the weather like in Tokyo?") # => "It is currently 72°F and sunny in Tokyo."
```

## Why Regent?

- **Transparent Decision Making**: Watch your agent's thought process as it reasons through problems
- **Flexible Architecture**: Easy to extend with custom tools and adapt to different use cases
- **Production Ready**: Built with tracing, error handling, and clean abstractions
- **Ruby-First Design**: Takes advantage of Ruby's elegant syntax and conventions

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/alchaplinsky/regent. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/alchaplinsky/regent/blob/main/CODE_OF_CONDUCT.md).

## Code of Conduct

Everyone interacting in the Regent project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/alchaplinsky/regent/blob/main/CODE_OF_CONDUCT.md).
