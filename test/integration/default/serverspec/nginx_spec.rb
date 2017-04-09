require 'serverspec'
set :backend, :exec

RSpec.configure do |c|
  c.before :all do
    c.path = '/sbin:/usr/sbin:/bin:/usr/bin'
  end
end

describe package('nginx') do
  it { should be_installed }
end

describe service('nginx') do
  it { should be_enabled }
  it { should be_running }
end

describe port('443') do
  it { should be_listening.on('0.0.0.0').with('tcp') }
end

#describe command('su - postgres -c \'psql -tA -c "show max_connections"\'') do
#  its(:stdout){ should match /^1000$/ }
#end
