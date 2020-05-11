require 'open3'

module Beaker
  class LocalConnection

    attr_accessor :logger, :hostname, :ip, :ip

    def initialize options = {}
      @logger = options[:logger]
      @ssh_env_file = File.expand_path(options[:ssh_env_file])
      @hostname = 'localhost'
      @ip = '127.0.0.1'
      @options = options
    end

    def self.connect options = {}
      connection = new options
      connection.connect
      connection
    end

    def connect options = {}
      @logger.debug "Local connection, no connection to start"
    end

    def close
      @logger.debug "Local connection, no connection to close"
    end

    def execute command, options = {}, stdout_callback = nil, stderr_callback = stdout_callback
      result = Result.new(@hostname, command)
      envs = {}
      if File.readable?(@ssh_env_file)
        File.foreach(@ssh_env_file) do |line|
          key,value = line.split('=')
          envs[key] = value
        end
      end

      begin
        std_out, std_err, status = Open3.capture3(envs, "sudo #{command}")
        result.stdout << std_out
        result.stderr << std_err
        result.exit_code = status.exitstatus
      rescue => e
        result.stderr << e.inspect
        result.exit_code = 1
      end

      result.finalize!
      @logger.last_result = result
      result
    end

    def scp_to source, target, options = {}

      result = Result.new(@hostname, [source, target])
      begin
        FileUtils.cp_r source, target
      rescue => e
        logger.warn "#{e.class} error in cp'ing. Forcing the connection to close, which should " <<
                        "raise an error."
      end

      result.stdout << "  CP'ed file #{source} to #{target}"
      result.exit_code = 0
      return result

    end

    def scp_from source, target, options = {}
      scp_to(target, source, options)
    end
  end
end
