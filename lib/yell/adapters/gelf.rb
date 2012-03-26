# encoding: utf-8

require 'socket'
require 'json'
require 'zlib'
require 'digest/md5'

module Yell #:nodoc:
  module Adapters #:nodoc:

    # GELF for Graylog2.
    class Gelf < Yell::Adapters::Base

      # Syslog severities
      Severities = [7, 6, 4, 3, 2, 1]

      # Combines syslog severities with internal representation:
      #   'DEBUG'   => 7
      #   'INFO'    => 6
      #   'WARN'    => 4
      #   'ERROR'   => 3
      #   'FATAL'   => 2
      #   'UNKNOWN' => 1
      SeverityMap = Hash[ *(Yell::Severities.zip(Severities).flatten) ]

      class Sender
        def initialize( *hosts )
          @hosts  = hosts
          @socket = UDPSocket.new
        end

        def send( *datagrams )
          datagrams.each do |d|
            @socket.send( d, 0, *host_and_port )
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

      def initialize( options = {}, &block )
        @uid = 0

        # initialize the UDP Sender
        @host = options.fetch(:host, 'localhost')
        @port = options.fetch(:port, 12201)

        max_chunk_size options.fetch(:max_chunk_size, :wan)

        super( options, &block )
      end


      # The sender (UDP Socket)
      def sender
        @sender ||= Yell::Adapters::Gelf::Sender.new( [@host, @port] )
      end

      # Close the UDP sender
      def close
        @sender.close if @sender.respond_to? :close

        @sender = nil
      end

      def max_chunk_size( val )
        @max_chunk_size = case val
          when :wan then 1420
          when :lan then 8154
          else val
        end
      end


      private

      def write!( event )
        # See https://github.com/Graylog2/graylog2-docs/wiki/GELF 
        # for formatting options.
        _datagrams = datagrams(
          'version'       => '1.0', 
          'facility'      => 'yell', 

          'level'         => SeverityMap[event.level], 
          'short_message' => event.message, 
          'timestamp'     => event.time.to_f, 
          'host'          => Socket.gethostname, 

          'file'          => event.file, 
          'line'          => event.line, 
          '_method'       => event.method,
          '_pid'          => Process.pid
        )

        sender.send( *_datagrams )
      rescue Exception => e
        close

        # re-raise the exception
        raise( e, caller )
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

    end

    register( :gelf, Yell::Adapters::Gelf )
    register( :graylog2, Yell::Adapters::Gelf )

  end
end

