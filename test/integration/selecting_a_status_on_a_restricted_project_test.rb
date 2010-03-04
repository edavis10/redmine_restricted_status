require 'test_helper'

class SelecingAStatusOnARestrictedProjectTest < ActionController::IntegrationTest
  def setup
    @user = User.generate_with_protected!(:password => 'test', :password_confirmation => 'test', :admin => true)
          @tracker = Tracker.generate!

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

      Member.generate!(:principal => @user, :roles => [@role], :project => @restricted_project)

    
      Setting.plugin_redmine_restricted_status = {
        'restricted_projects' => [@restricted_project.id.to_s],
        'allowed_statuses' => [@allowed_status1.id.to_s, @allowed_status2.id.to_s]
    }
    login_via_webrat(@user.login, 'test')
  end

  def login_via_webrat(login, password)
    visit "/login"
    fill_in 'Login', :with => login
    fill_in 'Password', :with => password
    click_button 'login'

    assert_response :success
    assert User.current.logged?

  end

  context "on a restricted project" do
    context "for a new issue" do
      should "only show the allowed statuses" do
        get "projects/#{@restricted_project.identifier}"
        assert_response :success

        click_link 'New Issue'
        assert_response :success

        assert_equal "/projects/#{@restricted_project.identifier}/issues/new", current_url

        assert_select 'select#issue_status_id' do
          assert_select 'option', :value => @allowed_status1.name
          assert_select 'option', :value => @allowed_status2.name
        end
        
      end
      
      should "not show the restricted status" do
        get "projects/#{@restricted_project.identifier}"
        assert_response :success

        click_link 'New Issue'
        assert_response :success

        assert_equal "/projects/#{@restricted_project.identifier}/issues/new", current_url

        assert_select 'select#issue_status_id' do
          assert_select 'option', :text => @restricted_status.name, :count => 0
        end

      end
    end

    context "for an existing issue" do
      setup do
        @issue = Issue.generate_for_project!(@restricted_project, :status => @allowed_status1)
      end

      should "only show the allowed statuses xxx" do
        visit "/issues/#{@issue.id}"
        assert_response :success
        
        click_link "Update"
        assert_response :success
        assert_equal "/issues/#{@issue.id}/edit", current_url

        assert_select 'select#issue_status_id' do
          assert_select 'option', :value => @allowed_status1.name
          assert_select 'option', :value => @allowed_status2.name
        end
        
      end
      
      should "not show the restricted status" do
        visit "/issues/#{@issue.id}"
        assert_response :success
        
        click_link "Update"
        assert_response :success
        assert_equal "/issues/#{@issue.id}/edit", current_url

        assert_select 'select#issue_status_id' do
          assert_select 'option', :text => @restricted_status.name, :count => 0
        end

      end

    end

  end
end
