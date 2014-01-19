# Crew

Write semantic scripts to setup and control your computer!

## "OMG... don't tell me you made another Chef, Puppet, Fabric, Sparkle, Babushka, Ansible, Capistrano..."

So, here's the deal... I love all those tools. They are great. But there is another tool I love too. Homebrew. I've been thinking about Homebrew and how hard it is to get scripts up and running on your computer. What we really need is a living, breathing Stack Overflow where we can store all the _best_ ways to do various tasks on various platforms. Something not only that tells us the best way to do the things, but actually _does_ the right thing. People obviously have different interpretations of what _best_ means, so it should be easy to change.

## Basics

Crew lets you run commands and parse the output. Crew comes with a number of built in tasks, which are contained in .crew files.

# Task

A task consists of two phases. In the *verify phase*, a task can assert things about a system. If any assertion fails, it causes a task to go into it's *running phase*. After a task is done running, it runs the verification again to ensure that a task has run.

# Contexts

Of course, tasks don't run in a vacuum. Tasks can run be across ssh or locally. Defining the set of machines and means of conecting to them constitutes a *context*.

## Commands

### General

#### `help`

Provides a useful help message.

#### `init`

Initializes crew. For crew to run, it needs to have a place to store the task files used when it ran last, so that you can have consistent runs inbetween executing commands.

#### `status`

Gets the current status of crew.

### General

#### `docs`

Generates and opens html docs

#### `list`

Lists all the tasks currently installed

#### `available`

Lists all the tasks available to be installed

#### `contexts`

Lists all available contexts

#### `update (task_name)`

Updates the specified task (or all of them)

#### `diff (task_name)`

Shows the differences between the task from source and your local copy

### Tasks

#### `install [task_name]`

Installs a task

#### `uninstall [task_name]`

Removes a task

#### `edit [task_name]`

Edits a task

#### `info [task_name]`

Shows information about a specific task

### Within a context

#### `shell`

Allows you to run commands from a shell

#### `run [task_name]`

Runs a specific task

#### `test [task_name]`

Runs tests for a specific

#### `test-all`

Runs all tests

## Concepts

### Task

The key concept is a *task*, the smallest unit of work. Tasks are meant to be the smallest unit of intent. Bigger intents are expressed by calling smaller bits in order. The purpose of a task is to wrap up an idea with an implementation designed to fit every platform as naturally as possible. For instance, to add a user, you'd invoke `user_add`. A task has two phases, a running phase and an optional verify phase. When a task is run, the logic it uses is the following:

1. Do I have a verifying phase? If so, verify.
   - If the task is verified, stop here.
2. Run the task, if there are no exceptions, return the result.
3. Repeat the verification phase.
   - Raise if it fails to verify.

A task has three methods it can use to interface with the underlying machine(s). Run a command and return the stdout, stdin and status code as a string, write a file to disk and restart your shell.

**sh_with_code**

This lets you run a command. It returns the standard out, standard error and status code.

**sh**

This lets you run a command, except, it raises an error on any non-zero exit code.

**save_data**

This lets you save data as a file.

**save_file**

This lets you save a local file to a remote file.

Take a look through the tasks directory to get a feel for different types of tasks.

### Task names

There is a simple rule about task names and directories tasks hold on to. They cannot contain anything other than a-z or 0-9. The way task names are constructed is by putting underscores between the directories and task name.

For instance, if you had the task `fs/read.crew` it would be invoked by calling `fs_read`. If a task name ends with an underscore, thats turned into a question mark in the method name, such as with `fs/exists_.crew`, which can be invoked as `fs_exist?`.

### Hints

So, how does this really work? When crew runs a command, it starts by reading system information on the target machine, and generating a series of hints depending on what it finds. For instance, on osx, it will supply the hint `:darwin`. When it's attempting to run a task, it looks for hints that match the already set hints.

For example:

    # say.crew

    desc "Say something!"

    arg :phrase

    run 'darwin' do
      sh "say #{escape(args.phrase)}"
    end

In this case, the say command will only run if you're on osx.

### Contexts

A context is the place in which commands get run. By default, you're running your commands in the Local context, that is, it's running on your machine!

You can define other contexts. Currently only SSH to a single host works as well, but other contexts are planned.

### Tests

Tasks should allow the ability to create tests around them, then, try those tasks on a large matrix of systems to ensure everything is still working. None of this is written but a boy can dream!

