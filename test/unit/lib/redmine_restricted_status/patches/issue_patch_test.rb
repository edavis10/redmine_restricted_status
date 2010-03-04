require File.dirname(__FILE__) + '/../../../../test_helper'

class RedmineRestrictedStatus::Patches::IssuePatchTest < ActiveSupport::TestCase
  context "#new_statuses_allowed_to" do
    setup do
      @user = User.generate_with_protected!(:password => 'test', :password_confirmation => 'test')
      @tracker = Tracker.generate!

      @non_restricted_project = Project.generate!(:trackers => [@tracker])
      @restricted_project = Project.generate!(:trackers => [@tracker])
      @allowed_status1 = IssueStatus.generate!(:is_default => true)
      @allowed_status2 = IssueStatus.generate!
      @restricted_status = IssueStatus.generate!
      @role = Role.generate!
      
      Workflow.generate(:tracker_id => @tracker.id,
                        :old_status => @allowed_status1,
                        :new_status => @allowed_status1,
                        :role => @role)
      Workflow.generate(:tracker_id => @tracker.id,
                        :old_status => @allowed_status1,
                        :new_status => @allowed_status2,
                        :role => @role)
      Workflow.generate(:tracker_id => @tracker.id,
                        :old_status => @allowed_status1,
                        :new_status => @restricted_status,
                        :role => @role)                        

      Member.generate!(:principal => @user, :roles => [@role], :project => @non_restricted_project)
      Member.generate!(:principal => @user, :roles => [@role], :project => @restricted_project)
      
      Setting.plugin_redmine_restricted_status = {
        'restricted_projects' => [@restricted_project.id.to_s],
        'allowed_statuses' => [@allowed_status1.id.to_s, @allowed_status2.id.to_s]
      }

      @issue = Issue.new
      @issue.tracker = @tracker
    end

    context "on a restricted project" do
      should "list only the allowed statuses" do
        @issue.project = @restricted_project

        statuses = @issue.new_statuses_allowed_to(@user)

        assert_same_elements [@allowed_status1, @allowed_status2], statuses
      end
      
      should "not list allowed statuses that are not part of the workflow" do
        out_of_workflow_status = IssueStatus.generate!
        @issue.project = @restricted_project

        statuses = @issue.new_statuses_allowed_to(@user)

        assert !statuses.include?(out_of_workflow_status)
      end        

    end

    context "on a non restricted project" do
      should "list all statuses" do
        @issue.project = @non_restricted_project

        statuses = @issue.new_statuses_allowed_to(@user)

        assert_same_elements [@allowed_status1, @allowed_status2, @restricted_status], statuses
      end
    end
  end
end

