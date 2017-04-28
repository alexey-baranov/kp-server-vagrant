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

describe command('curl -k --header "Host: kopnik.org" -H "Accept-Encoding: gzip" -I https://localhost/index.html') do
 its(:stdout){ should match /Content-Encoding: gzip/ }
end

describe command('curl -k --header "Host: kopnik.org" -H "Accept-Encoding: gzip" -I https://localhost/static/js/vendor.3f4f7e0071e4e286275b.js') do
 its(:stdout){ should match /Content-Encoding: gzip/ }
end

describe command('curl -k --header "Host: kopnik.org" -H "Accept-Encoding: gzip" -I https://localhost/sw.js') do
 its(:stdout){ should match /Cache-Control: max-age=0, private, must-revalidate/ }
 its(:stdout){ should match /Content-Encoding: gzip/ }
end

describe port('80') do
  it { should be_listening.on('0.0.0.0').with('tcp') }
end

describe command('curl -k --header "Host: kopnik.org" -H "Accept-Encoding: gzip" -I http://localhost/index.html') do
 its(:stdout){ should match /HTTP\/1\.1 301 Moved Permanently/ }
 its(:stdout){ should match /Location: https:\/\/kopnik.org\/index\.html/ }
end

describe command('curl -k --location --header "Host: kopnik.org" -H "Accept-Encoding: gzip" -I http://localhost/index.html') do
 its(:stdout){ should match /HTTP\/1\.1 301 Moved Permanently/ }
 its(:stdout){ should match /Location: https:\/\/kopnik\.org\/index\.html/ }
 its(:stdout){ should match /HTTP\/1\.1 200 OK/ }
 its(:stdout){ should match /Content-Encoding: gzip/ }
end

describe file('/etc/nginx/nginx.conf') do
 its(:content){ should match /client_max_body_size 25m;/ }
end
