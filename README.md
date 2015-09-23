# Tennis::Backend::Redis

A Redis backend for [tennis-jobs][tennis-jobs].

<a target="_blank" href="https://travis-ci.org/nicoolas25/tennis-redis"><img src="https://travis-ci.org/nicoolas25/tennis-redis.svg?branch=master" /></a>
<a target="_blank" href="https://codeclimate.com/github/nicoolas25/tennis-redis"><img src="https://codeclimate.com/github/nicoolas25/tennis-redis/badges/gpa.svg" /></a>
<a target="_blank" href="https://codeclimate.com/github/nicoolas25/tennis-redis/coverage"><img src="https://codeclimate.com/github/nicoolas25/tennis-redis/badges/coverage.svg" /></a>
<a target="_blank" href="https://rubygems.org/gems/tennis-jobs-redis"><img src="https://badge.fury.io/rb/tennis-jobs-redis.svg" /></a>

## Usage

Simply configure Tennis with this backend:

``` ruby
REDIS_URL = "redis://localhost:6379"

Tennis.configure do |config|
  config.backend = Tennis::Backend::Redis.new(logger: logger, url: REDIS_URL)
end
```

The backend take an extra argument nammed `namespace`.
Its default value is: `tennis`. All the redis keys are prefixed with `tennis:`.

## TODO

- Support the delay option.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).


[tennis-jobs]: https://github.com/nicoolas25/tennis
