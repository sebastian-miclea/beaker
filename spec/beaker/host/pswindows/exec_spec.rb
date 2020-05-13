require 'spec_helper'

module Beaker
  describe PSWindows::Exec do
    class PSWindowsExecTest
      include PSWindows::Exec

      def initialize(hash, logger)
        @hash = hash
        @logger = logger
      end

      def [](k)
        @hash[k]
      end

      def to_s
        "me"
      end

    end

    let (:opts)     { @opts || {} }
    let (:logger)   { double( 'logger' ).as_null_object }
    let (:instance) { PSWindowsExecTest.new(opts, logger) }

    context "rm" do

      it "deletes" do
        path = '/path/to/delete'
        corrected_path = '\\path\\to\\delete'
        expect( instance ).to receive(:execute).with("del /s /q #{corrected_path}").and_return(0)
        expect( instance.rm_rf(path) ).to be === 0
      end
    end

    context 'mv' do
      let(:origin)      { '/origin/path/of/content' }
      let(:destination) { '/destination/path/of/content' }

      it 'rm first' do
        expect( instance ).to receive(:execute).with("del /s /q #{destination.gsub(/\//, '\\')}").and_return(0)
        expect( instance ).to receive(:execute).with("move /y #{origin.gsub(/\//, '\\')} #{destination.gsub(/\//, '\\')}").and_return(0)
        expect( instance.mv(origin, destination) ).to be === 0

      end

      it 'does not rm' do
        expect( instance ).to receive(:execute).with("move /y #{origin.gsub(/\//, '\\')} #{destination.gsub(/\//, '\\')}").and_return(0)
        expect( instance.mv(origin, destination, false) ).to be === 0
      end
    end

    describe '#modified_at' do
      before do
        allow(instance).to receive(:execute).and_return(stdout)
      end

      context 'file exists' do
        let(:stdout) { 'True' }
        it 'sets the modified_at date' do
          file = 'C:\path\to\file'
          expect(instance).to receive(:execute).with("powershell Test-Path #{file} -PathType Leaf")
          expect(instance).to receive(:execute).with(
            "powershell (gci C:\\path\\to\\file).LastWriteTime = Get-Date -Year '1970'-Month '1'-Day '1'-Hour '0'-Minute '0'-Second '0'"
          )
          instance.modified_at(file, '197001010000')
        end
      end

      context 'file does not exist' do
        let(:stdout) { 'False' }
        it 'creates it and sets the modified_at date' do
          file = 'C:\path\to\file'
          expect(instance).to receive(:execute).with("powershell Test-Path #{file} -PathType Leaf")
          expect(instance).to receive(:execute).with("powershell New-Item -ItemType file #{file}")
          expect(instance).to receive(:execute).with(
            "powershell (gci C:\\path\\to\\file).LastWriteTime = Get-Date -Year '1970'-Month '1'-Day '1'-Hour '0'-Minute '0'-Second '0'"
          )
          instance.modified_at(file, '197001010000')
        end
      end
    end

    describe '#environment_string' do
      let(:host) { {'pathseparator' => ':'} }

      it 'returns a blank string if theres no env' do
        expect( instance.environment_string( {} ) ).to be == ''
      end

      it 'takes an env hash with var_name/value pairs' do
        expect( instance.environment_string( {:HOME => '/', :http_proxy => 'http://foo'} ) ).
          to be == 'set "HOME=/" && set "http_proxy=http://foo" && set "HTTP_PROXY=http://foo" && '
      end

      it 'takes an env hash with var_name/value[Array] pairs' do
        expect( instance.environment_string( {:LD_PATH => ['/', '/tmp']}) ).
          to be == "set \"LD_PATH=/:/tmp\" && "
      end
    end
  end
end
