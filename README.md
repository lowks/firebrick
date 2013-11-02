# Rinket


## Usage (temporary)

These usage instructions are temporary. Expect major changes to installation/usage instructions

I would suggest using a linux machine (even a virtual machine is fine).

* Clone this repository
* Run `mix deps.get` to install dependencies
* Run the following command to redirect port 25 traffic to port 2525.

        sudo iptables -t nat -A PREROUTING -p tcp -m tcp --dport 25 -j REDIRECT --to-ports 2525

* Start Riak with `riak start`
* Start the app with `iex -S mix server`. You will also get a console.
* To send a test mail, run `Rinket.Smtp.send_test_mail`

* Turn on Riak search in Riak's `app.config`
* Install Riak search hook by running `search-cmd install rinket_mails`

## Development

#### Ruby

You'll have to install Ruby if you are touching any of the assets (coffeescripts or stylesheets).

Run the following commands to install the `bundler` rubygem and then the other dependencies.

* `gem install bundler` - installs the bundler rubygem
* `bundle install` - Other ruby dependencies


#### Asset compilation

After installing the Ruby dependencies, you can compile assets using any of the following commands:

* `bundle exec rake assets:compile` - Compile assets

* `bundle exec rake assets:watch` - Watch assets for changes during development and compile them.

To compile changes automatically during development, use a file-watcher program like `watchman`.

If you are using watchman, run this:

    watchman -- trigger ~/projects/rinket/assets/ rinket_build '*.*' -- bundle exec rake assets:compile

On changes to any files in the assets dir, the assets will be compiled.

## Notes for development

* Do not handle db connection errors.
* Reference for email threading - http://www.jwz.org/doc/threading.html
* Forward port-25 to 2525

      sudo iptables -t nat -A PREROUTING -p tcp -m tcp --dport 25 -j REDIRECT --to-ports 2525

