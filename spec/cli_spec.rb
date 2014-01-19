# TODO, ulimately re-implement

# describe "Crew::CLI" do
#   describe "help" do
#     it "should run by default" do
#       cli.expects(:help)
#       cli.process([])
#     end
#
#     it "should run when called" do
#       cli.expects(:help)
#       cli.process(%w(help))
#     end
#   end
#
#   describe "init" do
#     it "should run" do
#       Crew::Home.expects(:init)
#       cli.process(%w(init))
#     end
#
#     it "should run with force" do
#       Crew::Home.expects(:init).with(has_entries(force: true))
#       cli.process(%w(init -f))
#     end
#   end
#
#   describe "docs" do
#     it "should run" do
#       Crew::Home.any_instance.expects(:docs)
#       cli.process(%w(docs))
#     end
#   end
#
#   describe "list" do
#     it "should run" do
#       Crew::Home.any_instance.expects(:list).at_least_once
#       cli.process(%w(list))
#     end
#   end
#
#   describe "available" do
#     it "should run" do
#       Crew::Home.any_instance.expects(:available)
#       cli.process(%w(available))
#     end
#   end
#
#   # TODO, this should be re-added
#   # describe "contexts" do
#   #  it "should run" do
#   #    cli = Crew::CLI.new
#   #    Crew::Home.any_instance.expects(:contexts).returns([])
#   #    cli.process(%w(contexts))
#   #  end
#   # end
#
#   describe "update" do
#     it "should run" do
#       Crew::Home.any_instance.expects(:update).with("task")
#       cli.process(%w(update task))
#     end
#   end
#
#   describe "diff" do
#     it "should for all tasks" do
#       Crew::Home.any_instance.expects(:diff)
#       cli.process(%w(diff))
#     end
#   end
#
#   describe "install" do
#     it "should run" do
#       Crew::Home.any_instance.expects(:install).with("task")
#       cli.process(%w(install task))
#     end
#   end
#
#   describe "uninstall" do
#     it "should run" do
#       Crew::Home.any_instance.expects(:uninstall).with("task")
#       cli.process(%w(uninstall task))
#     end
#   end
#
#   describe "edit" do
#     it "should run" do
#       Crew::Home.any_instance.expects(:edit).with("task")
#       cli.process(%w(edit task))
#     end
#   end
#
#   describe "info" do
#     it "should run" do
#       Crew::Home.any_instance.expects(:info).with("task")
#       cli.process(%w(info task))
#     end
#   end
#
#   describe "shell" do
#     it "should run" do
#       Crew::Home.any_instance.expects(:shell)
#       cli.process(%w(shell))
#     end
#
#     it "should run with context" do
#       stub = Crew::Home.any_instance
#       stub.expects(:shell).with("blah")
#       stub.expects(:setup_mode=).with(false)
#       cli.process(%w(shell -c blah))
#     end
#
#     it "should run with setup mode" do
#       stub = Crew::Home.any_instance
#       stub.expects(:shell)
#       stub.expects(:setup_mode=).with(true)
#       cli.process(%w(shell -s))
#     end
#   end
#
#   describe "run" do
#     it "should run" do
#       Crew::Home.any_instance.expects(:run).with(nil, "command")
#       cli.process(%w(run command))
#     end
#
#     it "should run with context" do
#       stub = Crew::Home.any_instance
#       stub.expects(:run).with("blah", "command")
#       stub.expects(:setup_mode=).with(false)
#       cli.process(%w(run command -c blah))
#     end
#
#     it "should run with setup mode" do
#       stub = Crew::Home.any_instance
#       stub.expects(:run).with(nil, "command")
#       stub.expects(:setup_mode=).with(true)
#       cli.process(%w(run command -s))
#     end
#   end
#
#   describe "test" do
#     it "should test" do
#       Crew::Home.any_instance.expects(:test).with(force: false, help: false).returns([0,0])
#       cli.process(%w(test))
#     end
#   end
# end
#