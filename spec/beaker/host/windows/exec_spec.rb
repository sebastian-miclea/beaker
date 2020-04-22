require 'spec_helper'

module Beaker
  describe Windows::Exec do
    class WindowsExecTest
      include Windows::Exec

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
    let (:instance) { WindowsExecTest.new(opts, logger) }

    describe '#prepend_commands' do
      it 'sets spacing correctly if both parts are defined' do
        allow( instance ).to receive( :is_cygwin? ).and_return( true )
        command_str = instance.prepend_commands( 'command', 'pants', { :cmd_exe => true } )
        expect( command_str ).to be === 'cmd.exe /c pants'
      end

      it 'sets spacing empty if one is not supplied' do
        allow( instance ).to receive( :is_cygwin? ).and_return( true )
        command_str = instance.prepend_commands( 'command', 'pants' )
        expect( command_str ).to be === 'pants'
      end

      it 'does not use cmd.exe by default' do
        allow( instance ).to receive( :is_cygwin? ).and_return( true )
        command_str = instance.prepend_commands( 'pants' )
        expect( command_str ).not_to match( /cmd\.exe/ )
      end

      it 'uses powershell if option is set' do
        allow( instance ).to receive( :is_cygwin? ).and_return( false )
        command_str = instance.prepend_commands('my_command', nil, powershell: true)
        expect( command_str).to eq('powershell')
      end
    end

    describe '#selinux_enabled?' do
      it 'does not call selinuxenabled' do
        expect(Beaker::Command).not_to receive(:new).with("sudo selinuxenabled")
        expect(instance).not_to receive(:exec).with(0, :accept_all_exit_codes => true)
        expect(instance.selinux_enabled?).to be === false
      end
    end

    describe '#modified_at' do
      require 'ostruct'
      before do
        allow(instance).to receive(:exec).and_return(OpenStruct.new(stdout: stdout))
      end
      context 'file exists' do
        let(:stdout) { 'True' }
        it 'sets the modified_at date' do
          file = 'C:\path\to\file'
          expect(Beaker::Command).to receive(:new).with("Test-Path #{file} -PathType Leaf", [], {:powershell=>true})
          expect(Beaker::Command).to receive(:new).with(
            "(gci C:\\path\\to\\file).LastWriteTime = Get-Date -Year '1970'-Month '1'-Day '1'-Hour '0'-Minute '0'-Second '0'",
            [],
            {:powershell=>true}
          )
          instance.modified_at(file, '197001010000')
        end
      end

      context 'file does not exist' do
        let(:stdout) { 'False' }
        it 'creates it and sets the modified_at date' do
          file = 'C:\path\to\file'
          expect(Beaker::Command).to receive(:new).with("Test-Path #{file} -PathType Leaf", [], {:powershell=>true})
          expect(Beaker::Command).to receive(:new).with("New-Item -ItemType file #{file}", [], {:powershell=>true})
          expect(Beaker::Command).to receive(:new).with(
            "(gci C:\\path\\to\\file).LastWriteTime = Get-Date -Year '1970'-Month '1'-Day '1'-Hour '0'-Minute '0'-Second '0'",
            [],
            {:powershell=>true}
          )
          instance.modified_at(file, '197001010000')
        end
      end
    end

    describe '#reboot' do
      it 'invokes the correct command on the host' do
        expect( Beaker::Command ).to receive( :new ).with( /^shutdown \/f \/r \/t 0 \/d p:4:1 \/c "Beaker::Host reboot command issued"/ ).and_return( :foo )
        expect( instance ).to receive( :exec ).with( :foo, :reset_connection => true )
        expect( instance ).to receive( :sleep )
        instance.reboot
      end
    end

    describe '#cygwin_installed?' do
      let (:response) { double( 'response' ) }

      it 'uses cygcheck to see if cygwin is installed' do
        expect( Beaker::Command ).to receive(:new).with("cygcheck --check-setup cygwin").and_return(:foo)
        expect( instance ).to receive( :exec ).with(:foo, :accept_all_exit_codes => true).and_return(response)
        expect( response ).to receive(:stdout).and_return('cygwin OK')
        expect(instance.cygwin_installed?).to eq(true)
      end

      it 'returns false when unable to find matching text' do
        expect( Beaker::Command ).to receive(:new).with("cygcheck --check-setup cygwin").and_return(:foo)
        expect( instance ).to receive( :exec ).with(:foo, :accept_all_exit_codes => true).and_return(response)
        expect( response ).to receive(:stdout).and_return('No matching text')
        expect(instance.cygwin_installed?).to eq(false)
      end
    end
  end
end
