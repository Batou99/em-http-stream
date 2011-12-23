$LOAD_PATH.unshift './examples'

require 'base_reader'

BaseReader.run(
        :host    => 'stream.meetup.com',
        :path    => '/2/rsvps'
        #:path    => '/2/open_events'
)
