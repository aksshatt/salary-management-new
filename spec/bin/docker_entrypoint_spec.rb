require "rails_helper"
require "open3"

RSpec.describe "bin/docker-entrypoint" do
  # Runs the entrypoint in a temp dir with a fake bin/rails that logs its arguments.
  def run_entrypoint(*args)
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p("#{dir}/bin")
      FileUtils.cp(Rails.root.join("bin/docker-entrypoint"), "#{dir}/bin/docker-entrypoint")
      File.write("#{dir}/bin/rails", "#!/bin/bash\necho \"$*\" >> calls.log\n")
      File.chmod(0o755, "#{dir}/bin/rails")

      _out, status = Open3.capture2e("bin/docker-entrypoint", *args, chdir: dir)
      expect(status).to be_success
      File.readlines("#{dir}/calls.log", chomp: true)
    end
  end

  it "prepares and seeds the database before starting the server" do
    expect(run_entrypoint("./bin/rails", "server", "-b", "0.0.0.0")).to eq([ "db:prepare", "db:seed", "server -b 0.0.0.0" ])
  end

  it "doesn't touch the database for other commands" do
    expect(run_entrypoint("./bin/rails", "console")).to eq([ "console" ])
  end
end
