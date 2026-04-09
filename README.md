# Morty

Morty is an accountant.

**Depends on:**

* Rails 8.1.2
* Ruby 4.0.1
* PostgreSQL 17

Source code

* [github.com/companygardener/morty][source]

## Installation

Add this line to your application's Gemfile:

    gem 'morty'

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install morty

Install migrations (Morty is a Rails engine):

    $ rake morty:install:migrations
    $ rake db:migrate

## Testing

Morty uses rspec and cucumber. Install them:

  $ bundle install

Run the test suite:

    $ rake db:reset
    $ rake

## Contributing

1. Fork it ( https://github.com/[my-github-username]/morty/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Copyright

Copyright © 2025-2026 Erik Peterson. Licensed under the MIT License.

[source]: https://github.com/companygardener/morty "Morty source"
