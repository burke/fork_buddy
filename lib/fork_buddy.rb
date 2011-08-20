require "fork_buddy/version"
require 'socket'

$_stack = []
$_children = []

module Kernel
  alias_method :__fork, :fork
  def fork(&block)
    $_children ||= []
    r = __fork(&block)
    $_children << r
    r
  end
end

class ForkBuddy

  class Server
    def initialize
      $socket, server = UNIXSocket.pair
      if __fork
        @processes = {}
        begin
          while line = server.recv(2**12) do
            process_command(line)
          end
        ensure
          @processes.each { |k, data|
            Process.kill("QUIT", data[:pid])
          }
        end
      end
    end

    def process_command(line)
      data = Marshal.load(line)
      puts "*** #{data.inspect}"

      case data[:command]
      when :register
        data.delete(:command)
        @processes[data[:forkpoint]] = data
      when :invalidate
        forkpoint = data[:forkpoint]
        @processes.each { |k,v|
          if k == forkpoint || v[:stack].include?(forkpoint)
            Process.kill("QUIT", v[:pid])
            v[:prune] = true
          end
        }

        restart_forkpoint = @processes.find{|k,v|k==forkpoint}[1][:stack].first
        restart = @processes.find{|k,v|k==restart_forkpoint}
        @processes.reject!{|k,v|v[:prune]}

        Process.kill("USR1", restart[1][:pid])
      end
    end

    def forkpoint(sym, &block)
      loop do
        if pid = __fork
          data = {
            command:   :register,
            forkpoint: sym,
            stack:     $_stack,
            pid:       pid
          }
          $socket.send Marshal.dump(data), 0

          # Spin until sent the USR1 signal, then run the next iteration of the loop.
          Kernel.trap("USR1") { throw(:next) }
          Kernel.trap("USR2") {
            # Inject code somehow.
          }
          catch(:next) { loop { sleep 10 } }
        else
          forkpoint_child(block, sym)
          exit(0) # end of execution reached
        end
      end
    end

    def forkpoint_child(block, sym)
      Kernel.trap("QUIT") {
        ($_children||[]).each { |child|
          puts "*** REAPING: #{child}"
          Process.kill("KILL", child) rescue nil
        }
        exit
      }
      $_stack.unshift sym
      block.call
    end

    def invalidate(sym)
      data = {
        command:   :invalidate,
        forkpoint: sym
      }
      $socket.send Marshal.dump(data), 0
    end

  end
end
