# frozen_string_literal: true

require 'spec_helper'

describe command('mesos-master --version') do
  its(:stdout) { should match(/mesos 1\.1\.0/) }
end

describe command('mesos-slave --version') do
  its(:stdout) { should match(/mesos 1\.1\.0/) }
end
