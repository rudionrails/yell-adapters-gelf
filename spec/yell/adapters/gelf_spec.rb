require 'spec_helper'

describe Yell::Adapters::Gelf do

  module SenderStub
    extend self

    def datagrams; @datagrams; end

    def send( *datagrams )
      @datagrams = datagrams
    end
  end

  let(:logger) { Yell::Logger.new }

  before do
    stub( Yell::Adapters::Gelf::Sender ).new( anything ) { SenderStub }
  end

  context "a new Yell::Adapters::Gelf instance" do
    subject { Yell::Adapters::Gelf.new }

    it { subject.host.should == 'localhost' }
    it { subject.port.should == 12201 }
    it { subject.facility.should == 'yell' }
    it { subject.max_chunk_size.should == 1420 }
  end

  context :host do
    let( :adapter ) { Yell::Adapters::Gelf.new }
    subject { adapter.host }

    before { adapter.host = 'hostname' }

    it { should == 'hostname' }
  end

  context :port do
    let( :adapter ) { Yell::Adapters::Gelf.new }
    subject { adapter.port }

    before { adapter.port = 1234 }

    it { should == 1234 }
  end

  context :max_chunk_size do
    let( :adapter ) { Yell::Adapters::Gelf.new }
    subject { adapter.max_chunk_size }

    context :wan do
      before { adapter.max_chunk_size = :wan }
      it { should == 1420 }
    end

    context :lan do
      before { adapter.max_chunk_size = :lan }
      it { should == 8154 }
    end

    context :other do
      before { adapter.max_chunk_size = "1234" }
      it { should == 1234 }
    end
  end

  context :write do
    let( :event ) { Yell::Event.new(logger, 1, 'Hello World') }
    let( :adapter ) { Yell::Adapters::Gelf.new }

    context "single" do
      let( :datagrams ) { SenderStub.datagrams }

      before do
        deflated = Zlib::Deflate.deflate( "*" * 1441000 ) # compresses to 1420 bytes
        mock( Zlib::Deflate ).deflate( anything ) { deflated }

        adapter.write event
      end

      it "should be one part" do
        datagrams.size.should == 1
      end

      it "should be a string" do
        datagrams[0].should be_kind_of String
      end

      it "should be zipped" do
        datagrams[0][0..1].bytes.should == [0x78, 0x9C] # zlib header
      end
    end

    context "chunked" do
      let( :datagrams ) { SenderStub.datagrams }

      before do
        deflated = Zlib::Deflate.deflate( "*" * 1442000 ) # compresses to 1421 bytes
        mock( Zlib::Deflate ).deflate( anything ) { deflated }

        adapter.write event
      end

      it "should be multiple parts" do
        datagrams.size.should == 2
      end

      it "should be multiple strings" do
        datagrams.each { |datagram| datagram.should be_kind_of String }
      end

      it "should be multiple GELF chunks" do
        # datagram assertions mostly taken from original gelf-rb gem
        datagrams.each_with_index do |datagram, index|
          datagram[0..1].should == "\x1e\x0f" # GELF header

          # datagram[2..9] is unique the message id
          datagram[10].ord.should == index # chunk number
          datagram[11].ord.should == datagrams.size # total chunk number
        end
      end
    end

    context :datagrams do
      after { adapter.write event }

      it "should receive :version" do
        mock.proxy( adapter ).datagrams( hash_including('version' => '1.0') )
      end

      it "should receive :facility" do
        mock.proxy( adapter ).datagrams( hash_including('facility' => adapter.facility) )
      end

      it "should receive :level" do
        mock.proxy( adapter ).datagrams( hash_including('level' => Yell::Adapters::Gelf::Severities[event.level]) )
      end

      it "should receive :short_message" do
        mock.proxy( adapter ).datagrams( hash_including('short_message' => event.messages.first) )
      end

      it "should receive :timestamp" do
        mock.proxy( adapter ).datagrams( hash_including('timestamp' => event.time.to_f) )
      end

      it "should receive :host" do
        mock.proxy( adapter ).datagrams( hash_including('host' => event.hostname) )
      end

      it "should receive :file" do
        mock.proxy( adapter ).datagrams( hash_including('file' => event.file) )
      end

      it "should receive :line" do
        mock.proxy( adapter ).datagrams( hash_including('line' => event.line) )
      end

      it "should receive :method" do
        mock.proxy( adapter ).datagrams( hash_including('_method' => event.method) )
      end

      it "should receive :pid" do
        mock.proxy( adapter ).datagrams( hash_including('_pid' => event.pid) )
      end

      context "given a Hash" do
        let( :event ) { Yell::Event.new(logger, 1, 'short_message' => 'Hello World', '_custom_field' => 'Custom Field') }

        it "should receive :short_message" do
          mock.proxy( adapter ).datagrams( hash_including('short_message' => 'Hello World') )
        end

        it "should receive :_custom_field" do
          mock.proxy( adapter ).datagrams( hash_including('_custom_field' => 'Custom Field') )
        end
      end

      context "given an Exception" do
        let( :exception ) { StandardError.new 'This is an error' }
        let( :event ) { Yell::Event.new(logger, 1, exception) }

        before do
          mock( exception ).backtrace.times(any_times) { [:back, :trace] }
        end

        it "should receive :short_message" do
          mock.proxy( adapter ).datagrams( hash_including('short_message' => "#{exception.class}: #{exception.message}") )
        end

        it "should receive :long_message" do
          mock.proxy( adapter ).datagrams( hash_including('long_message' => "back\ntrace") )
        end
      end

      context "given a Yell::Event with :options" do
        let( :event ) { Yell::Event.new(logger, 1, 'Hello World', "_custom_field" => 'Custom Field') }

        it "should receive :short_message" do
          mock.proxy( adapter ).datagrams( hash_including('short_message' => 'Hello World') )
        end

        it "should receive :_custom_field" do
          mock.proxy( adapter ).datagrams( hash_including('_custom_field' => 'Custom Field') )
        end
      end
    end
  end

end

