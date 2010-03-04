module RedmineRestrictedStatus
  module Patches
    module IssuePatch
      def self.included(base) # :nodoc:
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable # Send unloadable so it will not be unloaded in development

          
          def new_statuses_allowed_to_with_restricted_status(user)
            statuses = new_statuses_allowed_to_without_restricted_status(user)

            if Setting.plugin_redmine_restricted_status &&
                Setting.plugin_redmine_restricted_status['restricted_projects'].include?(self.project_id.to_s)

              return statuses.select {|s|
                Setting.plugin_redmine_restricted_status['allowed_statuses'] &&
                Setting.plugin_redmine_restricted_status['allowed_statuses'].include?(s.id.to_s)
              }
            else
              return statuses
            end
            
          end

          alias_method_chain :new_statuses_allowed_to, :restricted_status

        end

      end
      
      module ClassMethods
      end

      module InstanceMethods
      end
    end
  end
end
