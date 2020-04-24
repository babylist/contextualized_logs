# ContextualizedLogs

Online logging solution (like [Datadog](https://www.datadoghq.com)) have drastically transform the way we log.

An app will nowdays logs dozen (hundred) of logs per requests.

The issue is often to correlate this logs, with the initiating request (or job) and add shared metadata on this logs.

Here come `ContextualizedLogs`.

The main idea is to enhance your logs from your controller (including `ContextualizedController`, which use a before action), which will add the params to your logs (and some metadata about the request itself, like `request.uuid`).

This metadata are stored in a `ActiveSupport::CurrentAttributes` which is a singleton (reset per request).

Each subsequent logs in this thread (request) will also be enriched with this metadata, making it easier to find all the logs associated with a request (`uuid`, `ip`, `params.xxx`).

On top of this, logs can also be enriched by the ActiveRecord model they use (`create` or `find`) (models including `ContextualizedModel`). So any time a contextualized model is created or find, some metadata related to the model (`id`, ...) will also be added to the logs.

Allowing you to find all logs which "touched" this models.


So you now have:

```
get :show, { user_id: 123 }
which will log
{
  resource_name: ''
}
```


## Usage

### ContextualizedLogger

In order to enrich your logs, you needs to use (subclass of `ActiveSupport::Logger`) `ContextualizedLogger`

> ContextualizedLogger logs by default some request metadata following Datadog naming convention
> https://docs.hq.com/logs/processing/attributes_naming_convention/#source-code

```
Rails.application.configure do
  config.logger = ContextualizedLogs::ContextualizedLogger.new("log/#{Rails.env}.log")
end
````

### ContextualizedController

```
class Controller < ApplicationController
  include ContextualizedLogs::ContextualizedController
end
```

**All** (from the controller or any service, model, ... it used) this controller logs will now be enriched with some controller related metadata.

### ContextualizedModel

```
class Model < ActiveRecord::Base
  include ContextualizedLogs::ContextualizedModel

  # cherry picking which model value/column should be added to CurrentContext metadata
  contextualizable keys: {model_ids: :id}
end
```

If `ContextualizedLogs::CurrentContext.contextualized_model_enabled` is enable on the current tread, any Model which is created or find will add `{ context_values: { model_ids: ids } }`.
So if you fetch model (`id == 1`), and create model (`id == 2`), your logs will now contain `{ context_values: { model_ids: [1, 2] } }`.

### ContextualizedWorker

```
class Worker
  include ContextualizedLogs::ContextualizedWorker
  contextualized_worker true # enable logging of job enqueuing, performing, completing and failure
  contextualized_model true # enable logging of any (contextualized) model found or created while performing job

  # enable adding jobs args (cherry picked) to log metadata (CurrentContext) to be logged alongs any job logs
  def self.contextualize_args(args)
    { first: args.first }
  end
end
```

If `ContextualizedLogs::CurrentContext.contextualized_model_enabled` is enable on the current tread, any Model which is created or find will add `{ context_values: { model_ids: ids } }`.
So if you fetch model (`id == 1`), and create model (`id == 2`), your logs will now contain `{ context_values: { model_ids: [1, 2] } }`.

#### Metadata Customization

If you wish to logs different predefined metadata (`request.uuid`, `request.ip`, ...)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'contextualized_logs'
```

And then execute:

$ bundle install


## Roadmap

- [x] contextualized logger
- [x] contextualized controller
- [x] contextualized model
- [x] contextualized worker

## Specs

```
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/huguesbr/contextualized_logs. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the sidekiq_lockable_job project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/huguesbr/sidekiq_lockable_job/blob/master/CODE_OF_CONDUCT.md).
