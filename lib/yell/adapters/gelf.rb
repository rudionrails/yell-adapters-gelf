# encoding: utf-8

require 'socket'
require 'zlib'
require 'digest/md5'

require 'json'

module Yell #:nodoc:
  module Adapters #:nodoc:

    # GELF for Graylog2.
    class Gelf < Yell::Adapters::Base

      # Graylog severities
      Severities = [7, 6, 4, 3, 2, 1]

      class Sender
        def initialize( *hosts )
          @hosts  = hosts
          @socket = UDPSocket.new
        end

        def send( *datagrams )
          datagrams.each do |d|
            @socket.send(d, 0, *host_and_port)
          end
        end

        def close
          @socket.close unless @socket.closed?
        end

        private

        def host_and_port
          # Don't cycle the elements when only one present
          return @hosts.first if @hosts.size == 1

          # Cycle host and port
          host = @hosts.shift
          @hosts << host
          host
        end
      end


      setup do |options|
        @sender = nil
        @uid = 0

        self.facility = options.fetch(:facility, 'yell')

        # initialize the UDP Sender
        self.host = options.fetch(:host, 'localhost')
        self.port = options.fetch(:port, 12201)

        self.max_chunk_size = options.fetch(:max_chunk_size, :wan)
      end

      write do |event|
        message = format({
          'version'   => '1.0',

          'facility'  => facility,
          'level'     => Severities[event.level],
          'timestamp' => event.time.to_f,
          'host'      => event.hostname,

          'file'      => event.file,
          'line'      => event.line,
          '_method'   => event.method,
          '_pid'      => event.pid
        }, *event.messages )

        # https://github.com/Graylog2/graylog2-docs/wiki/GELF
        _datagrams = datagrams( message )

        sender.send( *_datagrams )
      end

      close do
        @sender.close if @sender.respond_to? :close
        @sender = nil
      end


      # Accessor to the Graylog host
      attr_accessor :host

      # Accessor to the Graylog port
      attr_accessor :port

      # Accessor to the Graylog facility
      attr_accessor :facility

      # Accessor to the Graylog chunk size
      attr_reader :max_chunk_size

      def max_chunk_size=( val )
        @max_chunk_size = case val
          when :wan then 1420
          when :lan then 8154
          else val.to_i
        end
      end


      private

      # The sender (UDP Socket)
      def sender
        @sender or open!
      end

      def open!
        @sender = Yell::Adapters::Gelf::Sender.new( [@host, @port] )
      end

      def datagrams( data )
        bytes = Zlib::Deflate.deflate( data.to_json ).bytes
        _datagrams = []

        if bytes.count > @max_chunk_size
          _id = Digest::MD5.digest( "#{Time.now.to_f}-#{object_id}-#{uid}" )[0, 8]

          num, count = 0, (bytes.count.to_f / @max_chunk_size).ceil
          bytes.each_slice( @max_chunk_size ) do |slice|
            _datagrams << "\x1e\x0f" + _id + [num, count, *slice].pack('C*')
            num += 1
          end
        else
          _datagrams << bytes.to_a.pack('C*')
        end

        _datagrams
      end

      def uid
        @uid += 1
      end

      def format( *messages )
        messages.inject(Hash.new) do |result, m|
          result.merge to_message(m)
        end
      end

      def to_message( message )
        case message
          when Hash
            message
          when Exception
            { "short_message" => "#{message.class}: #{message.message}" }.tap do |m|
              m.merge!( "long_message" => message.backtrace.join("\n") ) if message.backtrace
            end
          else { "short_message" => message.to_s }
        end
      end

    end

    register( :gelf, Yell::Adapters::Gelf )
    register( :graylog2, Yell::Adapters::Gelf )

  end
end

