$:.unshift "."
require File.dirname(__FILE__) + '/../spec_helper.rb'
require 'em-http-stream/json_stream'

include EventMachine

Host = "127.0.0.1"
Port = 9550

class JSONServer < EM::Connection
  attr_accessor :data
  def receive_data data
    $recieved_data = data
    send_data $data_to_send
    EventMachine.next_tick {
      close_connection if $close_connection
    }
  end
end



describe JSONStream do

  context "authentication" do
    it "should connect with basic auth credentials" do
      connect_stream :auth => "username:password"
      $recieved_data.should include('Authorization: Basic')
    end

    it "should connect with oauth credentials" do
      oauth = {
        :consumer_key => '1234567890',
        :consumer_secret => 'abcdefghijklmnopqrstuvwxyz',
        :access_key => 'ohai',
        :access_secret => 'ohno'
      }
      connect_stream :oauth => oauth
      $recieved_data.should include('Authorization: OAuth')
    end
  end

  context "on create" do

    it "should return stream" do
      EM.should_receive(:connect).and_return('TEST INSTANCE')
      stream = JSONStream.connect {}
      stream.should == 'TEST INSTANCE'
    end

    it "should connect to default host, port and path" do
      EM.should_receive(:connect).with do |host, port, handler, opts|
        host.should == 'localhost'
        port.should == 80
        opts[:path].should == '/'
      end
      stream = JSONStream.connect( {} )
    end

    it "should connect to provided host, port and path" do
      EM.should_receive(:connect).with do |host, port, handler, opts|
        host.should == 'a.host.com'
        port.should == 99
        opts[:path].should == '/some/path'
      end
      stream = JSONStream.connect( :host => 'a.host.com', :port=>99, :path=>'/some/path' )
    end

    it "should connect to the proxy if provided" do
      EM.should_receive(:connect).with do |host, port, handler, opts|
        host.should == 'my-proxy'
        port.should == 8080
        opts[:host].should == 'localhost'
        opts[:port].should == 80
        opts[:proxy].should == 'http://my-proxy:8080'
      end
      stream = JSONStream.connect(:proxy => "http://my-proxy:8080") {}
    end

  end

  context "on valid stream" do
    attr_reader :stream
    before :each do
      $body = File.readlines(fixture_path("twitter/tweets.txt"))
      $body.each {|tweet| tweet.strip!; tweet << "\n" }
      $data_to_send = http_response(200,"OK",{},$body)
      $recieved_data = ''
      $close_connection = false
    end

    it "should add no params" do
      connect_stream
      $recieved_data.should include('/ HTTP')
    end

    it "should add custom params" do
      connect_stream :params => {:name => 'test'}
      $recieved_data.should include('?name=test')
    end

    it "should parse headers" do
      connect_stream
      stream.code.should == 200
      stream.headers.keys.map{|k| k.downcase}.should include('content-type')
    end

    it "should parse headers even after connection close" do
      connect_stream
      stream.code.should == 200
      stream.headers.keys.map{|k| k.downcase}.should include('content-type')
    end

    it "should extract records" do
      connect_stream :user_agent => 'TEST_USER_AGENT'
      $recieved_data.upcase.should include('USER-AGENT: TEST_USER_AGENT')
    end

    it 'should allow custom headers' do
      connect_stream :headers => { 'From' => 'twitter-stream' }
      $recieved_data.upcase.should include('FROM: TWITTER-STREAM')
    end

    it "should deliver each item" do
      items = []
      connect_stream do
        stream.each_item do |item|
          items << item
        end
      end
      # Extract only the tweets from the fixture
      tweets = $body.map{|l| l.strip }.select{|l| l =~ /^\{/ }
      items.size.should == tweets.size
      tweets.each_with_index do |tweet,i|
        items[i].should == tweet
      end
    end

    it "should send correct user agent" do
      connect_stream
    end
  end

  shared_examples_for "network failure" do
    it "should reconnect on network failure" do
      connect_stream do
        stream.should_receive(:reconnect)
      end
    end

    it "should not reconnect on network failure when not configured to auto reconnect" do
      connect_stream(:auto_reconnect => false) do
        stream.should_receive(:reconnect).never
      end
    end

    it "should reconnect with 0.25 at base" do
      connect_stream do
        stream.should_receive(:reconnect_after).with(0.25)
      end
    end

    it "should reconnect with linear timeout" do
      connect_stream do
        stream.nf_last_reconnect = 1
        stream.should_receive(:reconnect_after).with(1.25)
      end
    end

    it "should stop reconnecting after 100 times" do
      connect_stream do
        stream.reconnect_retries = 100
        stream.should_not_receive(:reconnect_after)
      end
    end

    it "should notify after reconnect limit is reached" do
      timeout, retries = nil, nil
      connect_stream do
        stream.on_max_reconnects do |t, r|
          timeout, retries = t, r
        end
        stream.reconnect_retries = 100
      end
      timeout.should == 0.25
      retries.should == 101
    end
  end

  context "on network failure" do
    attr_reader :stream
    before :each do
      $data_to_send = ''
      $close_connection = true
    end

    it "should timeout on inactivity" do
      connect_stream :stop_in => 1.5 do
        stream.should_receive(:reconnect)
      end
    end

    it "should not reconnect on inactivity when not configured to auto reconnect" do
      connect_stream(:stop_in => 1.5, :auto_reconnect => false) do
        stream.should_receive(:reconnect).never
      end
    end

    it_should_behave_like "network failure"
  end

  context "on server unavailable" do

    attr_reader :stream

    # This is to make it so the network failure specs which call connect_stream
    # can be reused. This way calls to connect_stream won't actually create a
    # server to listen in.
    def connect_stream_without_server(opts={},&block)
      connect_stream_default(opts.merge(:start_server=>false),&block)
    end
    alias_method :connect_stream_default, :connect_stream
    alias_method :connect_stream, :connect_stream_without_server

    it_should_behave_like "network failure"
  end

  context "on application failure" do
    attr_reader :stream
    before :each do
      $data_to_send = "HTTP/1.1 401 Unauthorized\r\nWWW-Authenticate: Basic realm=\"Firehose\"\r\n\r\n"
      $close_connection = false
    end

    it "should reconnect on application failure 10 at base" do
      connect_stream do
        stream.should_receive(:reconnect_after).with(10)
      end
    end

    it "should not reconnect on application failure 10 at base when not configured to auto reconnect" do
      connect_stream(:auto_reconnect => false) do
        stream.should_receive(:reconnect_after).never
      end
    end

    it "should reconnect with exponential timeout" do
      connect_stream do
        stream.af_last_reconnect = 160
        stream.should_receive(:reconnect_after).with(320)
      end
    end

    it "should not try to reconnect after limit is reached" do
      connect_stream do
        stream.af_last_reconnect = 320
        stream.should_not_receive(:reconnect_after)
      end
    end
  end

  context "on stream with chunked transfer encoding" do
    attr_reader :stream
    before :each do
      $recieved_data = ''
      $close_connection = false
    end

    it "should ignore empty lines" do
      body_chunks = ["{\"screen"+"_name\"",":\"user1\"}\n\n\n{","\"id\":9876}\n\n"]
      $data_to_send = http_response(200,"OK",{},body_chunks)
      items = []
      connect_stream do
        stream.each_item do |item|
          items << item
        end
      end
      items.size.should == 2
      items[0].should == '{"screen_name":"user1"}'
      items[1].should == '{"id":9876}'
    end

    it "should parse full entities even if split" do
      body_chunks = ["{\"id\"",":1234}\n{","\"id\":9876}"]
      $data_to_send = http_response(200,"OK",{},body_chunks)
      items = []
      connect_stream do
        stream.each_item do |item|
          items << item
        end
      end
      items.size.should == 2
      items[0].should == '{"id":1234}'
      items[1].should == '{"id":9876}'
    end
  end

end
