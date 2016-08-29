require 'spec_helper'

# mesos master service
describe 'mesos master service' do
  it 'should be running' do
    case RSpec.configuration.os
    when 'Debian'
      expect(service('mesos-master')).to be_running
    end
  end
end

describe port(5050) do
  it { should be_listening }
end

describe command('curl -sD - http://localhost:5050/health -o /dev/null') do
  its(:stdout) { should match(/200 OK/) }
end

describe file('/var/log/mesos/mesos-master.INFO') do
  its(:content) { should match(/INFO level logging started/) }
  its(:content) { should match(/Elected as the leading master!/) }
end

describe command('curl -sD - http://localhost:5050/state.json') do
  its(:stdout) { should match(/"logging_level":"INFO"/) }
  its(:stdout) { should match(/"cluster":"MyMesosCluster"/) }
  its(:stdout) { should match(/"authenticate_(slaves|agents)":"false"/) }
  its(:stdout) { should match(/"activated_(slaves|agents)":\s*1/) }
end

describe file('/etc/mesos-chef/mesos-master') do
  its(:content) { should contain 'exec 1> >\\(exec logger -p user.info -t "mesos-master"\\)' }
  its(:content) { should contain 'exec 2> >\\(exec logger -p user.err  -t "mesos-master"\\)' }
end
