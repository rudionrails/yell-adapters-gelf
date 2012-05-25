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

After you set-up [Graylog2](http://www.graylog2.org) accordingly, 
you may use the Gelf adapter just like any other.

```ruby
logger = Yell.new :gelf

# or alternatively with the block syntax
logger = Yell.new do |l|
  l.adapter :gelf
end

logger.info 'Hello World!'
```

Now check your Graylog2 web server for the received message. By default, 
the gelf adapter will send the following information to Graylog2:

`facility`: The GELF facility (default: 'yell')  
`level`: The current log level  
`timestamp`: The time when the log event occured  
`host`: The current hostname  
`file`: The name of the file where the log event occured  
`line`: The line in the file where the log event occured  
`_method`: The method where the log event occured  
`_pid`: The PID of your current process  


### Example: Running with a different GELF facility

```ruby
logger = Yell.new :gelf, :facility => 'my own facility'

# or with the block syntax
logger = Yell.new do |l|
  l.adapter :gelf, :facility => 'my own facility'
end
```

### Example: Running Graylog2 on a different host or port

```ruby
logger = Yell.new :gelf, :host => '127.0.0.1', :port => 1234

# or with the block syntax
logger = Yell.new do |l|
  l.adapter :gelf, :host => '127.0.0.1', :port => 1234
end

logger.info 'Hello World!'
```

### Example: Passing additional keys to the adapter

```ruby
logger = Yell.new :gelf

logger.info "Hello World", "_thread_id" => Thread.current.object_id, 
                           "_current_user_id" => current_user.id
```

Copyright &copy; 2012 Rudolf Schmidt, released under the MIT license

