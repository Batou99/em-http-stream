require 'rubygems'
lib_path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift lib_path unless $LOAD_PATH.include?(lib_path)

require 'em-http-stream/json_stream'

class BaseReader
  def self.run(options)
    EventMachine::run do
      stream = EventMachine::JSONStream.connect(options)

      stream.each_item do |item|
        puts "*" * 80
        puts item
      end

      stream.on_error do |message|
        puts "error: #{message}\n"
      end

      stream.on_reconnect do |timeout, retries|
        puts "reconnecting in: #{timeout} seconds\n"
      end

      stream.on_max_reconnects do |timeout, retries|
        puts "Failed after #{retries} failed reconnects\n"
      end

      trap('INT') {
        stream.stop
        EventMachine.stop if EventMachine.reactor_running?
      }
      trap('TERM') {
        stream.stop
        EventMachine.stop if EventMachine.reactor_running?
      }
    end
  end
end

