# frozen_string_literal: true

#
# Cookbook Name:: mesos
# Recipe:: master
#
# Copyright (C) 2015 Medidata Solutions, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

class Chef::Recipe
  include MesosHelper
end

include_recipe 'mesos::install'

# Mesos configuration validation
ruby_block 'mesos-master-configuration-validation' do
  block do
    # Get Mesos --help
    help = Mixlib::ShellOut.new("#{node['mesos']['master']['bin']} --help")
    help.run_command
    help.error!
    # Extract options
    options = help.stdout.strip.scan(/^  --(?:\[no-\])?(\w+)/).flatten - ['help']
    # Check flags are in the list
    node['mesos']['master']['flags'].keys.each do |flag|
      unless options.include?(flag)
        Chef::Application.fatal!("Invalid Mesos configuration option: #{flag}. Aborting!", 1000)
      end
    end
  end
end

# ZooKeeper Exhibitor discovery
if node['mesos']['zookeeper_exhibitor_discovery'] && node['mesos']['zookeeper_exhibitor_url']
  zk_nodes = MesosHelper.discover_zookeepers_with_retry(node['mesos']['zookeeper_exhibitor_url'])

  if zk_nodes.nil?
    Chef::Application.fatal!('Failed to discover zookeepers. Cannot continue.')
  end

  node.override['mesos']['master']['flags']['zk'] = 'zk://' + zk_nodes['servers'].sort.map { |s| "#{s}:#{zk_nodes['port']}" }.join(',') + '/' + node['mesos']['zookeeper_path']
end

# Mesos master configuration wrapper
template 'mesos-master-wrapper' do
  path '/etc/mesos-chef/mesos-master'
  owner 'root'
  group 'root'
  mode '0750'
  source 'wrapper.erb'
  variables(bin:    node['mesos']['master']['bin'],
            flags:  node['mesos']['master']['flags'],
            syslog: node['mesos']['master']['syslog'])
  notifies :restart, 'service[mesos-master]'
end

systemd_service 'mesos-master' do
  unit do
    description 'Mesos mesos-master'
    after 'network.target'
    wants 'network.target'
  end

  service do
    environment node['mesos']['master']['env']
    exec_start '/etc/mesos-chef/mesos-master'
    restart 'on-failure'
    restart_sec 20
    limit_nofile 16384
  end

  install do
    wanted_by 'multi-user.target'
  end
  action [:create, :enable]
  notifies :restart, 'service[mesos-master]'
end

# Mesos master service definition
service 'mesos-master' do
  supports status: true, restart: true
  action %i[enable start]
end
