class ForkBuddy
  class SavePoint
    def initialize(options)
      @options = options
      pause
    end

    def resume(&block)
      @action = block
      fork(&@action)
    end

    def pause

    end

    def resume(&block)

    end

  end

  class Server
    def initialize(opts={})
      @sockets = opts[:socket]
      @fork_pool = {}
    end

    def option(sym)

    end

    def register(sym)
      pid = fork { wait }
      @fork_pool[sym] = pid
    end

    def wait
      loop { sleep 10 }
    end
  end
end
