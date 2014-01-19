describe "Crew::Task" do
  it "should run a task without a verify step" do
    @task = task("simple") do
      run do
        "done"
      end
    end
    assert_equal "done", @task.run!
  end

  it "should not run a task if the verify step succeeds" do
    @task = task("simple") do
      verify { true }
      run { raise }
    end
    @task.run!
    assert true
  end

  it "should raise if the verify step always fails run a task if the verify step succeeds" do
    called = false

    @task = task("simple") do
      verify { raise }
      run { called = true }
    end
    begin
      @task.run!
      fail
    rescue
      assert called
    end
  end

  it "should succeed if the verify step succeeds" do
    called = false
    @task = task("simple") do
      verify { raise unless called }
      run { called = true }
    end
    @task.run!
    assert called
  end

  describe "task with one arg" do
    before do
      @task = task("simple") do
        arg :name
        run { args.name }
      end
    end

    it "should allow passing in args" do
      assert_equal "ella-1", @task.run!("ella-1")
    end

    it "should disallow passing too many args" do
      assert_raises(ArgumentError) { @task.run!("ella-1", "ella-2") }
    end

    it "should disallow passing no arguments" do
      assert_raises(ArgumentError) { @task.run! }
    end
  end

  describe "task with two args" do
    before do
      @task = task("simple") do
        arg :name1
        arg :name2
        run { [args.name1, args.name2] }
      end
    end

    it "should allow passing in multiple args" do
      out = @task.run! "ella-1", "ella-2"
      assert_equal ["ella-1", "ella-2"], out
    end

    it "should disallow passing too many args" do
      assert_raises(ArgumentError) { @task.run!("ella-1", "ella-2", "ella-3") }
    end

    it "should disallow passing no arguments" do
      assert_raises(ArgumentError) { @task.run! }
    end
  end
end
