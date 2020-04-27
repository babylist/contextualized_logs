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

    $ curl --referer "referer" --user-agent "user_agent" -H "Origin: http://localhost" http://localhost/my_controller?param=a

```json
{
  "syslog": {
    "env": "development",
    "host": "localhost"
  },
  "type": "INFO",
  "time": "2020-04-24T19:52:51.452+02:00",
  "log_type": "log",
  "resource_name": "mycontroller_show",
  "http": {
    "referer": "referer",
    "request_id": "xxxx-xxxx-xxxx-xxxx",
    "useragent": "user_agent",
    "origin": "http://localhost"
  },
  "network": {
    "client": {
      "ip": "127.0.0.1",
      "remote_addr": "127.0.0.1",
      "remote_ip": "127.0.0.1",
      "x_forwarded_for": "127.0.0.1"
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
  contextualize_model true

  def show
    User.find(params[:id])
  end
end
```

    $ curl http://localhost/users/1

```json
{
  "syslog": {
    "env": "development",
    "host": "localhost"
  },
  "type": "INFO",
  "time": "2020-04-24T19:52:51.452+02:00",
  "log_type": "log",
  "context_values": {
    "user_ids": [1]
  },
  "resource_name": "mycontroller_show",
  "http": {
    "request_id": "xxxx-xxxx-xxxx-xxxx"
  },
  "network": {
    "client": {
      "ip": "127.0.0.1",
      "remote_addr": "127.0.0.1",
      "remote_ip": "127.0.0.1",
      "x_forwarded_for": "127.0.0.1"
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
  contextualize_model true

  def show
    user_id = params[:id]
    User.find(user_id)
    UserTrackerWorker.perform_async(user_id, 'show')
  end
end

class UserTrackerWorker
  include Sidekiq::Worker
  include ContextualizedLogs::ContextualizedWorker
  contextualize_worker true
  contextualize_model true
  def self.contextualize_args(args)
    { user_id: args.first, action: args.last }
  end

  def perform(user_id, action)
    UserTracker.create(user_id: user_id, action: action)
  end
end
```

    $ curl http://localhost/users/1

```json
{
  "syslog": {
    "env": "development",
    "host": "localhost"
  },
  "type": "INFO",
  "time": "2020-04-24T19:52:51.452+02:00",
  "log_type": "log",
  "context_values": {
    "user_ids": [1]
  },
  "enqueued_jobs_ids": ["1234-xxxx-xxxx-xxxx"],
  "resource_name": "mycontroller_show",
  "http": {
    "request_id": "xxxx-xxxx-xxxx-xxxx"
  },
  "network": {
    "client": {
      "ip": "127.0.0.1",
      "remote_addr": "127.0.0.1",
      "remote_ip": "127.0.0.1",
      "x_forwarded_for": "127.0.0.1"
    }
  }
}
```

```json
{
  "syslog": {
    "env": "development",
    "host": "localhost"
  },
  "type": "INFO",
  "time": "2020-04-24T19:52:51.452+02:00",
  "log_type": "log",
  "message": "sidekiq: completing job UserWorker: 1234-xxxx-xxxx-xxxx, on queue default",
  "job": {
    "worker": "UserWorker",
    "id": "1234-xxxx-xxxx-xxxx",
    "args": {
      "user_id": 1,
      "action": "show"
    }
  },
  "context_values": {
    "user_ids": [1],
    "user_tracker_ids": [1]
  },
  "enqueued_jobs_ids": ["xxxx-xxxx-xxxx-xxxx"],
  "resource_name": "mycontroller_show",
  "http": {
    "request_id": "xxxx-xxxx-xxxx-xxxx"
  },
  "network": {
    "client": {
      "ip": "127.0.0.1",
      "remote_addr": "127.0.0.1",
      "remote_ip": "127.0.0.1",
      "x_forwarded_for": "127.0.0.1"
    }
  }
}
```

```json
{
  "syslog": {
    "env": "development",
    "host": "localhost"
  },
  "type": "INFO",
  "time": "2020-04-24T19:52:51.452+02:00",
  "log_type": "log",
  "message": "sidekiq: completing job UserWorker: 1234-xxxx-xxxx-xxxx, on queue default",
  "job": {
    "worker": "UserWorker",
    "id": "1234-xxxx-xxxx-xxxx",
    "args": {
      "user_id": 1,
      "action": "show"
    }
  },
  "context_values": {
    "user_ids": [1],
    "user_tracker_ids": [1]
  },
  "enqueued_jobs_ids": ["xxxx-xxxx-xxxx-xxxx"],
  "resource_name": "mycontroller_show",
  "http": {
    "request_id": "xxxx-xxxx-xxxx-xxxx"
  },
  "network": {
    "client": {
      "ip": "127.0.0.1",
      "remote_addr": "127.0.0.1",
      "remote_ip": "127.0.0.1",
      "x_forwarded_for": "127.0.0.1"
    }
  }
}
```

## Demo

### Rails Demo


#### start rails

  $ bin/setup
  $ bin/rails server

#### start sidekiq

  $ bundle exec sidekiq

#### tail logs

  $ tail -f log/development

#### do some requests

```shell
curl -X POST -d '{"value": "value"}' -H 'Content-Type: application/json' "http://localhost:3000/model"
curl "http://localhost:3000/model/1"
curl "http://localhost:3000/model"
curl -X DELETE "http://localhost:3000/model/1"
```

### Asciinema

Thanks to [Asciinema](https://asciinema.org)!

    $ rake demo

[![asciicast](https://asciinema.org/a/324084.svg)](https://asciinema.org/a/324084)


### Datadog

Contextualized Logs is particuly useful if you have a online service to parse/search the logs, like [Datadog](https://www.datadoghq.com).

Here is a video of log searching using [Datadog](https://www.datadoghq.com)

<video src="https://huguesbr-public.s3-us-west-1.amazonaws.com/datadog.mp4" width="960" height="600" controls preload></video>

## Usage

### ContextualizedLogger

In order to enrich your logs, you needs to use (subclass of `ActiveSupport::Logger`) `ContextualizedLogger`

> ContextualizedLogger logs by default some request metadata following Datadog naming convention
> https://docs.hq.com/logs/processing/attributes_naming_convention/#source-code

```ruby
Rails.application.configure do
  config.logger = ContextualizedLogs::ContextualizedLogger.new("log/#{Rails.env}.log")
end
````

### ContextualizedController

```ruby
class Controller < ApplicationController
  include ContextualizedLogs::ContextualizedController
end
```

**All** (from the controller or any service, model, ... it used) this controller logs will now be enriched with some controller related metadata.

### ContextualizedModel

```ruby
class Model < ActiveRecord::Base
  include ContextualizedLogs::ContextualizedModel

  # cherry picking which model value/column should be added to CurrentContext metadata
  contextualizable keys: {model_ids: :id}
end
```

If `ContextualizedLogs::CurrentContext.contextualize_model_enabled` is enable on the current tread, any Model which is created or find will add `{ context_values: { model_ids: ids } }`.
So if you fetch model (`id == 1`), and create model (`id == 2`), your logs will now contain `{ context_values: { model_ids: [1, 2] } }`.

### ContextualizedWorker

```ruby
class Worker
  include ContextualizedLogs::ContextualizedWorker
  contextualize_worker true # enable logging of job enqueuing, performing, completing and failure
  contextualize_model true # enable logging of any (contextualized) model found or created while performing job

  # enable adding jobs args (cherry picked) to log metadata (CurrentContext) to be logged alongs any job logs
  def self.contextualize_args(args)
    { first: args.first }
  end
end
```

If `ContextualizedLogs::CurrentContext.contextualize_model_enabled` is enable on the current tread, any Model which is created or find will add `{ context_values: { model_ids: ids } }`.
So if you fetch model (`id == 1`), and create model (`id == 2`), your logs will now contain `{ context_values: { model_ids: [1, 2] } }`.

## Configuration

`ContextualizedLogs` work with zero configuration by default.

It will log:
  - basic request info (`http.request_id`, ....) on each (contextualized) controller
  - basic job info (`enqueued_jobs_ids` on controller which enqueue the job, `job.worker, job.id` on each worker logs, and one log for `enqueuing`, `started`, `processing`, `completing`, [`failure`]) on each (contextualized) worker
  - contextualized models are not logged by default, and needs to be enable on each controller, worker

If you wish to logs different predefined metadata (`request.uuid`, `request.ip`, ...), or logging mechanism, you can use an initializer `ContextualizedLogs.configure`.

```ruby
# config/initializers/contextualized_logs.rb
require 'contextualized_logs'

module ContextualizedLogs
  configure do |config|
    # enable logging of contextualized model values in all (contextualized) controller by default
    # can be manually enabled on each controller otherwise (contextualize_model true)
    config.controller_default_contextualize_model = true # default: false
    # enable logging of worker enqueing/performing/completing/[failure] in all (contextualized) worker by default
    # can be manually enabled on each worker otherwise (contextualize_worker true)
    config.worker_default_contextualize_worker = true # default: true
    # enable logging of contextualized model values in all (contextualized) worker by default
    # can be manually enabled on each worker otherwise (contextualize_model true)
    config.worker_default_contextualize_model = true # default: false
    # customize logs at Logger level (not in context of a controller request or worker job)
    config.log_formatter = proc do |severity, timestamp, progname, msg|
      # call the default formatter
      log = ContextualizedLogger.default_formatter.call(severity, timestamp, progname, msg)
      # enhance log with Datadog APM trace correlation
      log = JSON.parse(log)
      datadog_correlation = Datadog.tracer.active_correlation
      log.merge!(
        dd: {
          trace_id: datadog_correlation.trace_id,
          span_id: datadog_correlation.span_id
        },
        ddsource: ['ruby']
      )
      # add your own log
      log.merge!(
        my_custom_log_value: 'my_custom_log_value'
      )
      log.to_json + "\n"
    end
    # customize logs extracted from controller (ie: request, ...)
    config.controller_default_contextualizer = proc do |controller|
      # call the default request logging
      ContextualizedController.contextualize_request(controller)
      if controller.current_user
        ContextualizedController.current_context.attributes.merge!(
          usr: {
            id: controller.current_user.id
          }
        )
      end
    end
  end
end
```

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

```shell
$ rake

DummyController
  should set request details
  should NOT set enable model context values
  should set resource_name
  should set request details

ContextualizedModelDummyController
  should set request details
  should set enable model context values

ContextualizedLogs::ContextualizedLogger
  format log
  includes stack
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
    with contextualize_model_enabled == true
      set contextualizable values
    with contextualize_model_enabled == false
      set contextualizable values
  with CurrentContext.contextualize_model_enabled == true
    behaves like after_create context
      .after_create
        set context
    behaves like after_find context
      .after_find
        does
  with CurrentContext.contextualize_model_enabled == false
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
      behaves like it client yield
        should eq true
    with contextualized worker
      DOES change job context
      DOES log job enqueued
      behaves like it client yield
        should eq true
      with contextualized model
        DOES enable model context values

ContextualizedLogs::Sidekiq::Middleware::Server::RestoreCurrentContext
  with uncontextualized worker
    DOES NOT log job
    DOES NOT log job failure
    behaves like it server yield
      should eq true
    behaves like enable model context values
      model context values
  with contextualized worker
    behaves like it server yield
      should eq true
    behaves like log job failure
      log job failure
    behaves like log with context
      log with context
    behaves like enable model context values
      model context values
  with contextualized model worker
    behaves like it server yield
      should eq true
    behaves like log job failure
      log job failure
    behaves like log with context
      log with context
    behaves like enable model context values
      model context values
  with contextualized model worker
    log with args
    behaves like it server yield
      should eq true
    behaves like log job failure
      log job failure
    behaves like log with context
      log with context
    behaves like enable model context values
      model context values

ContextualizedLogs
  has a version number

CustomContextController
  should set request details
  should set custom attributes

Finished in 1.27 seconds (files took 1.58 seconds to load)
48 examples, 0 failures
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
