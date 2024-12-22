
![regent_light](https://github.com/user-attachments/assets/62564dac-b8d7-4dc0-9b63-64c6841b5872)

# Regent
**Regent** is library for building AI agents with Ruby.

> [!WARNING]
> Regent is currently an experiment intended to explore patterns for building easily traceable and debuggable AI agents of different architectures. It is not yet intended to be used in production and is currently in development.
>

## Install

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

```ruby
llm = Langchain::LLM::OpenAi(...)
agent = Regent::Agent.new(llm)

agent.execute("What is the weather in London today?")
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/alchaplinsky/regent. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/alchaplinsky/regent/blob/main/CODE_OF_CONDUCT.md).

## Code of Conduct

Everyone interacting in the Regent project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/alchaplinsky/regent/blob/main/CODE_OF_CONDUCT.md).
