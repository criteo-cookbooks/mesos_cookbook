# frozen_string_literal: true

name             'mesos'
maintainer       'Criteo'
maintainer_email 'g.seux@criteo.com'
license          'Apache-2.0'
description      'Installs/Configures Apache Mesos'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '4.0.0'
source_url       'https://github.com/criteo-forks/mesos_cookbook'
issues_url       'https://github.com/criteo-forks/mesos_cookbook/issues'

supports 'centos'

%w[java yum].each do |cookbook|
  depends cookbook
end

depends 'systemd', '<= 3.2.2'
chef_version '>= 11' if respond_to?(:chef_version)
