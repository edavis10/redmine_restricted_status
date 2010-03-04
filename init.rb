require 'redmine'

# similar to config/environments/*.rb
case Rails.env
when "test"
  config.gem "webrat"
end

# Patches to the Redmine core.
require 'dispatcher'

Dispatcher.to_prepare :redmine_restricted_status do
  require_dependency 'issue'
  unless Issue.included_modules.include? RedmineRestrictedStatus::Patches::IssuePatch
    Issue.send(:include, RedmineRestrictedStatus::Patches::IssuePatch)
  end
end


Redmine::Plugin.register :redmine_restricted_status do
  name 'Restricted Status'
  author 'Eric Davis'
  url 'https://projects.littlestreamsoftware.com/projects/redmine-misc'
  author_url 'http://www.littlestreamsoftware.com'
  description 'Plugin to restrict status changes in specific projects.'
  version '0.1.0'


  settings(:partial => 'settings/restricted_status_settings',
           :default => {
             'restricted_projects' => [],
             'allowed_statuses' => []
           })
  
end
