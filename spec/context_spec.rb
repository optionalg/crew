describe "Crew::Context" do
  it "should dispatch a task" do
    task("simple2") do
      run do
        "simple2"
      end
    end

    task_s2 = task("simple") do
      run do
        simple2
      end
    end
    assert_equal "simple2", task_s2.run!
  end

  describe "with a hinted task" do
    before do
      context.load do
        task "simple2" do
          run do
            "simple2"
          end

          run :osx do
            "simple2 osx"
          end
        end

        task("simple") do
          run do
            simple2
          end
        end
      end
    end

    it "should dispatch a hinted task" do
      assert_equal "simple2", context.task("simple").run!
    end

    it "should dispatch a hinted task" do
      context.load { hint 'osx' }
      assert_equal "simple2 osx", context.task("simple").run!
    end
  end
end
