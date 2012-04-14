Yell Gelf - Graylog2 Adapter for Your Extensible Logging Library

If you are not yet familiar with **Yell - Your Extensible Logging Library** 
check out the githup project under https://github.com/rudionrails/yell or jump 
directly into the Yell wiki at https://github.com/rudionrails/yell/wiki.

Just in case you wonder: GELF means Graylog Extended Log Format. Read all 
it at http://www.graylog2.org/about/gelf.

[![Build Status](https://secure.travis-ci.org/rudionrails/yell-adapters-gelf.png?branch=master)](http://travis-ci.org/rudionrails/yell-adapters-gelf)

The Graylog adapter for Yell works and is tested with ruby 1.8.7, 1.9.x, jruby 1.8 and 1.9 mode, rubinius 1.8 and 1.9 as well as ree.


## Installation

System wide:

```console
gem install yell-adapters-gelf
```

Or in your Gemfile:

```ruby
gem "yell-adapters-gelf"
```

## Usage

After you set-up Graylog2 accordingly, you may use the Gelf adapter just like 
any other.

```ruby
logger = Yell.new :gelf

logger.info "Hello World"
# Check your Graylog2 web server for the received message.
```

Or alternatively with the block syntax:

```ruby
logger = Yell.new do |l|
  l.adapter :gelf
end

logger.info 'Hello World!'
```

If you are running Graylog2 on a different server or port, you can pass those 
options to the adapter:

```ruby
logger = Yell.new :gelf, :host => 'hostname', :port => 1234

# Or with the block syntax
logger = Yell.new do |l|
  l.adapter :gelf, :host => 'hostname', :port => 1234
end

logger.info 'Hello World!'
```

Copyright &copy; 2012 Rudolf Schmidt, released under the MIT license

