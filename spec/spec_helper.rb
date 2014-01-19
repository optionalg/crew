$: << File.expand_path("../../lib", __FILE__)

ENV['SUDO_PASSWORD'] = 'test-password'

require 'crew'
require 'minitest/autorun'
require 'mocha/setup'

class FakeHome
  def logger
    @logger = Crew::Logger.new(true)
  end

  def context
    @context ||= Crew::Context.new(self, "context")
  end

  def find_and_add_task(name)
    # do nothing
  end

  def callbacks
    {before: [], after: []}
  end
end

class MiniTest::Spec

  def cli
    @cli ||= Crew::CLI.new
  end

  def crew_run(*args)
    crew "run", *args
  end

  def crew(*args)
    # stdout, stderr pipes
    rout, wout = IO.pipe
    rerr, werr = IO.pipe

    pid = fork do
      STDOUT.reopen(wout)
      STDERR.reopen(werr)
      Crew::CLI.run(args)
      exit(0)
    end
    werr.close
    wout.close # file handles have to all be closed in order for the "read" method, below, to be able to know
    # that it's done reading data, so it can return.  See also http://devver.wordpress.com/2009/10/22/beware-of-pipe-duplication-in-subprocesses/
    # rerr.rewind
    _, status = Process.waitpid2(pid)
    [rout.read, rerr.read, status.exitstatus]
  end

  def home
    @home ||= FakeHome.new
  end

  def context
    home.context
  end

  def task(name, *args, &blk)
    context.add_task(name, &blk)
    context.task(name)
  end
end
