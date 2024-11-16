module Roadshow
  module Process
    VERBOSE = !!ENV["VERBOSE"]? || false

    class LoggingProxy < IO
      def initialize(@other_io : IO)
      end

      def read(slice : Bytes)
        @other_io.read(slice)
      end

      def write(slice : Bytes) : Nil
        STDOUT.write(slice)
        @other_io.write(slice)
      end
    end

    def self.run(cmd : String, args : Array(String), input : IO, output : IO, error : IO, env : Hash(String, String) = {} of String => String)
      if VERBOSE
        puts "Running #{cmd} with args #{args.inspect}"
        input = LoggingProxy.new(input)
        output = LoggingProxy.new(output)
        error = LoggingProxy.new(error)
      end

      ::Process.run(cmd, args, input: input, output: output, error: error, env: env)
    end
  end
end
