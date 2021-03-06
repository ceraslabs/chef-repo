#
# Cookbook Name:: application_java
# Library:: resource_java_remote_file
#
# Copyright 2012, ZephirWorks
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

require 'chef/resource/cookbook_file'

class Chef
  class Resource
    class JavaCookbookFile < Chef::Resource::CookbookFile

      alias :user :owner

      def initialize(name, run_context=nil)
        super
        @resource_name = :java_cookbook_file
        @provider = Chef::Provider::JavaCookbookFile
        @deploy_to = nil
        @deployer_id = nil
        @action = "deploy"
        @allowed_actions.push(:deploy, :force_deploy)
      end

      def provider
        Chef::Provider::JavaCookbookFile
      end

      def deploy_to(args=nil)
        set_or_return(
          :deploy_to,
          args,
          :kind_of => String
        )
      end

      def source(args=nil)
        set_or_return(
          :source,
          args,
          :kind_of => String
        )
      end

      def release_path
        @release_path ||= @deploy_to + "/releases/app.war"
      end

      def method_missing(name, *args, &block)
        Chef::Log.info "java_cookbook_file missing(#{name}, #{args.inspect}), ignoring it"
      end

    end
  end
end
