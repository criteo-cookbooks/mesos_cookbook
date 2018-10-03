# frozen_string_literal: true

#
# Cookbook Name:: mesos
# Recipe:: install
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

include_recipe 'java'

include_recipe 'mesos::repo' if node['mesos']['repo']

case node['platform_family']
when 'debian'
  %w[unzip default-jre-headless libcurl3 libsvn1].each do |pkg|
    package pkg do
      action :install
    end
  end

  package 'mesos' do
    # --no-install-recommends to skip installing zk. unnecessary.
    options node['mesos']['package_options'].join(' ')
    if node['mesos']['version']
      action :install
      # Glob is necessary to select the deb version string
      version "#{node['mesos']['version']}*"
    else
      action :upgrade
    end
  end
when 'rhel'
  %w[unzip libcurl subversion].each do |pkg|
    yum_package pkg do
      action :install
    end
  end

  yum_package 'mesos' do
    if node['mesos']['version']
      version node['mesos']['version']
    else
      action :upgrade
    end
    allow_downgrade true
    options node['mesos']['package_options'].join(' ')
  end
end

directory '/etc/mesos-chef'

# Disable services by default
%w(slave master).each do |type|
  service "mesos-#{type}-default" do
    service_name "mesos-#{type}"
    action %i[stop disable]
    not_if { node['recipes'].include?("mesos::#{type}") }
  end
end
