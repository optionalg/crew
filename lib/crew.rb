require 'erb'     # for templating
require 'digest'  # for task digests
require 'net/ssh' # for ssh
require 'net/scp'
require 'etc'
require 'rainbow' # for colorized console output
require 'pry'     # for the shell, TODO get rid of this
require 'set'     # all over
require 'json'    # for task test storage

require 'crew/version'
require 'crew/util'
require 'crew/logger'
require 'crew/docs'
require 'crew/home/dsl'
require 'crew/home'
require 'crew/tester/preparer/dsl'
require 'crew/tester/preparer'
require 'crew/tester/dsl'
require 'crew/tester'
require 'crew/context/dsl'
require 'crew/context/local'
require 'crew/context/ssh'
require 'crew/context/vagrant'
require 'crew/context/fusion'
require 'crew/context'
require 'crew/task/arguments'
require 'crew/task/arguments/dsl'
require 'crew/task/test'
require 'crew/task/dsl'
require 'crew/task'
require 'crew/cli'
require 'crew/cli/tasks'
require 'crew/cli/contexts'

module Crew
end
