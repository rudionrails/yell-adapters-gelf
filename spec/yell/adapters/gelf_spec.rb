require 'spec_helper'

describe Yell::Adapters::Gelf do

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
    let( :event ) { Yell::Event.new( 'INFO', 'Hello World' ) }
    let( :adapter ) { Yell::Adapters::Gelf.new }

    it "should pass datagrams to Sender" do
      deflated = Zlib::Deflate.deflate( "*" * 1441000 ) # compresses to 1420 bytes
      mock( Zlib::Deflate ).deflate( anything ) { deflated }

      any_instance_of( Yell::Adapters::Gelf::Sender ) { |s| mock(s).send( is_a(String) ) }

      adapter.write event
    end

    it "should chunk the message when too long" do
      deflated = Zlib::Deflate.deflate( "*" * 1442000 ) # compresses to 1421 bytes
      mock( Zlib::Deflate ).deflate( anything ) { deflated }

      any_instance_of( Yell::Adapters::Gelf::Sender ) do |s| 
        mock(s).send( is_a(String), is_a(String) )
      end

      adapter.write event
    end

    context :datagrams do
      before do
        any_instance_of( Yell::Adapters::Gelf::Sender ) do |s|
          mock( s ).send( anything )
        end
      end

      after { adapter.write event }

      it "should receive :version" do
        mock.proxy( adapter ).datagrams( hash_including('version' => '1.0') )
      end

      it "should receive :facility" do
        mock.proxy( adapter ).datagrams( hash_including('facility' => adapter.facility) )
      end

      it "should receive :level" do
        mock.proxy( adapter ).datagrams( hash_including('level' => Yell::Adapters::Gelf::SeverityMap[event.level]) )
      end

      it "should receive :short_message" do
        mock.proxy( adapter ).datagrams( hash_including('short_message' => event.message) )
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
    end
  end

end

