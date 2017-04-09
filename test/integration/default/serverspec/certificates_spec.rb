require 'serverspec'
set :backend, :exec

RSpec.configure do |c|
  c.before :all do
    c.path = '/sbin:/usr/sbin:/bin:/usr/bin'
  end
end

describe package('cryptography') do
  it { should be_installed.by('pip') }
end

#describe command('su - postgres -c \'psql -tA -c "show max_connections"\'') do
#  its(:stdout){ should match /^1000$/ }
#end
