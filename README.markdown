# em-http-stream

Simple Ruby client library for consuming HTTP streams with [chunked transfer encoding](http://en.wikipedia.org/wiki/Chunked_transfer_encoding).
Examples of such streams are Twitter's Streaming API, Meetup Streaming API, and hopefully many more in the future.
Uses [EventMachine](http://rubyeventmachine.com/) for connection handling. Handles re-connections.
JSON format only.

## Credits

All credit should go to [Vladimir Kolesnikov](https://github.com/voloko/twitter-stream) for his awesome twitter-stream gem
which I tweaked slightly to generalize away from being Twitter specific.

## Install

    gem install em-http-stream

## Usage

    require 'rubygems'
    require 'em-http-stream/json_stream'
    
    EventMachine::run {
      stream = EventMachine::JSONStream.connect(
        :path    => '/1/statuses/filter.json?track=football',
        :auth    => 'LOGIN:PASSWORD'
      )

      stream.each_item do |item|
        # item is unparsed JSON string.
      end

      stream.on_error do |message|
        # No need to worry here. It might be an issue with Twitter. 
        # Log message for future reference. JSONStream will try to reconnect after a timeout.
      end
      
      stream.on_max_reconnects do |timeout, retries|
        # Something is wrong on your side. Send yourself an email.
      end
    }
    

## Examples

To receive Meetup.com updates on all open events run
    ruby ./examples/meetup.rb

To receive Twitter status updates (sampled stream) run
    ruby ./examples/twitter_filter.rb <twitter_username> <twitter_password>

To track tweets about baseball run
    ruby ./examples/twitter_filter.rb <twitter_username> <twitter_password>

