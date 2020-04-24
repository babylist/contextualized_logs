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

All logs are (by default in json format)

```ruby
class MyController < ApplicationController
  include ContextualizedLogs::ContextualizedController
end
```

```
curl --referer 'referer' --user-agent 'user_agent' -H "Origin: http://localhost" http://localhost/my_controller?param=a

# development.log
{
  syslog: {
    env: 'development',
    host: 'localhost'
  },
  type: 'INFO',
  time: '2020-04-24T19:52:51.452+02:00',
  log_type: 'log',
  resource_name: 'mycontroller_show',
  http: {
    referer: 'referer',
    request_id: 'xxxx-xxxx-xxxx-xxxx'
    useragent: 'user_agent',
    origin: 'http://localhost'
  },
  network: {
    client: {
      ip: '127.0.0.1',
      remote_addr: '127.0.0.1',
      remote_ip: '127.0.0.1',
      x_forwarded_for: '127.0.0.1'
    }
  }
}
```

```ruby
class User < ActiveRecord::Base
  include ContextualizedLogs::ContextualizedModel
  contextualizable { user_ids: :id }
end

class UserController < ApplicationController
  include ContextualizedLogs::ContextualizedController
  contextualized_model true

  def show
    User.find(params[:id])
  end
end
```

```
curl http://localhost/users/1

# development.log
{
  syslog: {
    env: 'development',
    host: 'localhost'
  },
  type: 'INFO',
  time: '2020-04-24T19:52:51.452+02:00',
  log_type: 'log',
  context_values: {
    user_ids: [1]
  },
  resource_name: 'mycontroller_show',
  http: {
    request_id: 'xxxx-xxxx-xxxx-xxxx'
  },
  network: {
    client: {
      ip: '127.0.0.1',
      remote_addr: '127.0.0.1',
      remote_ip: '127.0.0.1',
      x_forwarded_for: '127.0.0.1'
    }
  }
}
```

```ruby
class User < ActiveRecord::Base
  include ContextualizedLogs::ContextualizedModel
  contextualizable { user_ids: :id }
end

class UserTracker < ActiveRecord::Base
  include ContextualizedLogs::ContextualizedModel

  belongs_to :user

  contextualizable { user_tracker_ids: :id }
end

class UserController < ApplicationController
  include ContextualizedLogs::ContextualizedController
  contextualized_model true

  def show
    user_id = params[:id]
    User.find(user_id)
    UserTrackerWorker.perform_async(user_id, 'show')
  end
end

class UserTrackerWorker
  include Sidekiq::Worker
  include ContextualizedLogs::ContextualizedWorker
  contextualized_worker true
  contextualized_model true
  def self.contextualize_args(args)
    { user_id: args.first, action: args.last }
  end

  def perform(user_id, action)
    UserTracker.create(user_id: user_id, action: action)
  end
end
```

```
curl http://localhost/users/1

# development.log
{
  syslog: {
    env: 'development',
    host: 'localhost'
  },
  type: 'INFO',
  time: '2020-04-24T19:52:51.452+02:00',
  log_type: 'log',
  context_values: {
    user_ids: [1]
  },
  enqueued_jobs_ids: ['1234-xxxx-xxxx-xxxx']
  resource_name: 'mycontroller_show',
  http: {
    request_id: 'xxxx-xxxx-xxxx-xxxx'
  },
  network: {
    client: {
      ip: '127.0.0.1',
      remote_addr: '127.0.0.1',
      remote_ip: '127.0.0.1',
      x_forwarded_for: '127.0.0.1'
    }
  }
}
{
  syslog: {
    env: 'development',
    host: 'localhost'
  },
  type: 'INFO',
  time: '2020-04-24T19:52:51.452+02:00',
  log_type: 'log',
  message: 'sidekiq: completing job UserWorker: 1234-xxxx-xxxx-xxxx, on queue default',
  job: {
    worker: 'UserWorker',
    id: '1234-xxxx-xxxx-xxxx',
    args: {
      user_id: 1,
      action: 'show'
    }
  }
  context_values: {
    user_ids: [1],
    user_tracker_ids: [1]
  },
  enqueued_jobs_ids: ['xxxx-xxxx-xxxx-xxxx']
  resource_name: 'mycontroller_show',
  http: {
    request_id: 'xxxx-xxxx-xxxx-xxxx'
  },
  network: {
    client: {
      ip: '127.0.0.1',
      remote_addr: '127.0.0.1',
      remote_ip: '127.0.0.1',
      x_forwarded_for: '127.0.0.1'
    }
  }
}
{
  syslog: {
    env: 'development',
    host: 'localhost'
  },
  type: 'INFO',
  time: '2020-04-24T19:52:51.452+02:00',
  log_type: 'log',
  message: 'sidekiq: completing job UserWorker: 1234-xxxx-xxxx-xxxx, on queue default',
  job: {
    worker: 'UserWorker',
    id: '1234-xxxx-xxxx-xxxx',
    args: {
      user_id: 1,
      action: 'show'
    }
  }
  context_values: {
    user_ids: [1],
    user_tracker_ids: [1]
  },
  enqueued_jobs_ids: ['xxxx-xxxx-xxxx-xxxx']
  resource_name: 'mycontroller_show',
  http: {
    request_id: 'xxxx-xxxx-xxxx-xxxx'
  },
  network: {
    client: {
      ip: '127.0.0.1',
      remote_addr: '127.0.0.1',
      remote_ip: '127.0.0.1',
      x_forwarded_for: '127.0.0.1'
    }
  }
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
- [ ] lograge

## Specs

```
ContextualizedLogs::ContextualizedController
  .contextualize_requests
    should set request details

ContextualizedLogs::ContextualizedLogger
  format log
  includes stack (PENDING: Temporarily skipped with xit)
  format exception
  inject context
  dump
    respect severity debug (default)
    dump message
    dump exception

ContextualizedLogs::ContextualizedModel
  .contextualizable
    set contextualizable keys
  .contextualize
    with contextualized_model_enabled == true
      set contextualizable values
    with contextualized_model_enabled == false
      set contextualizable values

ContextualizedLogs
  has a version number

Pending: (Failures listed here are expected and do not affect your suite's status)

  1) ContextualizedLogs::ContextualizedLogger includes stack
     # Temporarily skipped with xit
     # ./spec/contextualized_logs/contextualized_logger_spec.rb:61


Finished in 0.01959 seconds (files took 0.89851 seconds to load)
12 examples, 0 failures, 1 pending

DummyController
  should set request details
  should NOT set enable model context values
  should set resource_name
  should set request details

ContextualizedModelDummyController
  should set request details
  should set enable model context values

ContextualizedLogs::ContextualizedModel
  with CurrentContext.contextualized_model_enabled == true
    behaves like after_create context
      .after_create
        set context
    behaves like after_find context
      .after_find
        does
  with CurrentContext.contextualized_model_enabled == false
    behaves like after_create context
      .after_create
        set context
    behaves like after_find context
      .after_find
        does

ContextualizedLogs::Sidekiq::Middleware::Client::InjectCurrentContext
  ContextualizedWorker
    with uncontextualized worker
      DOES NOT change job context
      DOES NOT log job enqueued
      DOES NOT enable model context values
      behaves like it yield
        should eq true
    with contextualized worker
      DOES change job context
      DOES log job enqueued
      behaves like it yield
        should eq true
      with contextualized model
        DOES enable model context values

ContextualizedLogs::Sidekiq::Middleware::Server::RestoreCurrentContext
  with uncontextualized worker
    DOES NOT log job
    DOES NOT log job failure
    behaves like it yield
      should eq true
    behaves like enable model context values
      enable model context values
  with contextualized worker
    behaves like it yield
      should eq true
    behaves like log job failure
      log job failure
    behaves like log with context
      log with context
    behaves like enable model context values
      enable model context values
  with contextualized model worker
    behaves like it yield
      should eq true
    behaves like log job failure
      log job failure
    behaves like log with context
      log with context
    behaves like enable model context values
      enable model context values
  with contextualized model worker
    log with args
    behaves like it yield
      should eq true
    behaves like log job failure
      log job failure
    behaves like log with context
      log with context
    behaves like enable model context values
      enable model context values

Finished in 0.29379 seconds (files took 1.35 seconds to load)
35 examples, 0 failures
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
