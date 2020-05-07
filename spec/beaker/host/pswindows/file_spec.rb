require 'spec_helper'

module Beaker
  describe PSWindows::File do
    class PSWindowsFileTest
      include PSWindows::File
      include Beaker::DSL::Wrappers

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
    let (:instance) { PSWindowsFileTest.new(opts, logger) }

    describe '#cat' do
      it 'reads output for file' do
        path = '/path/to/delete'
        expect(instance).to receive(:exec)
        expect(Beaker::Command).to receive(:new).with('powershell.exe', array_including("-Command type #{path}"))
        instance.cat(path)
      end
    end

    describe '#tmpdir' do
      let(:tmp_path) { 'C:\\tmpdir\\' }
      before do
        allow(instance).to receive(:execute).with(anything)
      end
      context 'with dirname sent' do
        let(:name) { 'my_dir' }
        it 'returns the path to my_dir' do
          expect(instance).to receive(:execute).with('[System.IO.Path]::GetTempPath()').and_return(double(stdout: tmp_path))
          expect(instance).to receive(:execute).with("New-Item -Path '#{tmp_path}' -Force -Name '#{name}' -ItemType 'directory'")
          expect(instance.tmpdir(name)).to eq(File.join(tmp_path, name))
        end
      end

      context 'without dirname sent' do
        let(:name) { '' }
        let(:random_dir) { 'dirname' }
        before do
          allow(instance).to receive(:execute).with('[System.IO.Path]::GetRandomFileName()').and_return(double(stdout: random_dir))
        end
        it 'returns the path to random name dir' do
          expect(instance).to receive(:execute).with('[System.IO.Path]::GetTempPath()').and_return(double(stdout: tmp_path))
          expect(instance).to receive(:execute).with("New-Item -Path '#{tmp_path}' -Force -Name '#{random_dir}' -ItemType 'directory'")
          expect(instance.tmpdir(name)).to eq(File.join(tmp_path, random_dir))
        end
      end
    end
  end
end
