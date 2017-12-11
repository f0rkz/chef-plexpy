#
# Cookbook:: plexpy
# Recipe:: default
#
# Author:: Nick Gray (f0rkz@f0rkznet.net)
#
# Copyright:: 2017 f0rkznet.net
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
package 'git' do
  action :install
end

package 'python2' do
  action :install
end

package 'virtualenv' do
  action :install
end

user node['plexpy']['deploy_user'] do
  comment 'Plexpy deployment user'
  shell '/bin/sh'
  system true
end

directory node['plexpy']['deploy_dir'] do
  owner node['plexpy']['deploy_user']
  group node['plexpy']['deploy_user']
  mode '0755'
  recursive true
  action :create
end

execute 'install virtualenv' do
  command <<-EOF
  virtualenv #{node['plexpy']['deploy_dir']}/virtualenv
  EOF
  user node['plexpy']['deploy_user']
  group node['plexpy']['deploy_user']
  action :run
  not_if { ::File.directory?("#{node['plexpy']['deploy_dir']}/virtualenv") }
end

directory "#{node['plexpy']['deploy_dir']}/plexpy" do
  owner node['plexpy']['deploy_user']
  group node['plexpy']['deploy_user']
  mode '0755'
  recursive true
  action :create
end

git "#{node['plexpy']['deploy_dir']}/plexpy" do
  repository 'https://github.com/JonnyWong16/plexpy.git'
  user node['plexpy']['deploy_user']
  group node['plexpy']['deploy_user']
  action :sync
end

template '/etc/systemd/system/plexpy.service' do
  source 'plexpy.service.erb'
  owner node['plexpy']['deploy_user']
  group node['plexpy']['deploy_user']
  mode '0744'
  variables({
    deploy_user: node['plexpy']['deploy_user'],
    deploy_dir: node['plexpy']['deploy_dir'],
    venv_python: "#{node['plexpy']['deploy_dir']}/virtualenv/bin/python",
    plexpy_port: node['plexpy']['port']
  })
end

service 'plexpy' do
  supports status: true
  action [:enable, :start]
end
