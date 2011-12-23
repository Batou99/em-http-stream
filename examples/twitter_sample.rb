$LOAD_PATH.unshift './examples'

require 'base_reader'

fail "Usage: ruby ./examples/twitter_sample.rb <twitter_username> <twitter_password>" unless ARGV[0] && ARGV[1]
BaseReader.run(
        :auth =>"#{ARGV[0]}:#{ARGV[1]}",
        :ssl => true,
        :host    => 'stream.twitter.com',
        :path    => '/1/statuses/sample.json'
)