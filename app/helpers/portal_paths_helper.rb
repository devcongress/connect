# Links between the portals (and to the main-app setup pages) that work from
# any context: main-app views, portal engines and Phlex components.
module PortalPathsHelper
  # Holds the app's mounted engine proxies (dashboard_portal, developer_portal, ...)
  # so the helpers below don't depend on the caller's routing context.
  class Routes
    include Rails.application.routes.url_helpers
    include Rails.application.routes.mounted_helpers

    def _routes_context = self
  end

  def self.routes
    Routes.new
  end

  def home_dashboard_path
    PortalPathsHelper.routes.dashboard_portal.root_path
  end

  def public_home_path
    PortalPathsHelper.routes.root_path
  end

  def notification_settings_dashboard_path
    PortalPathsHelper.routes.dashboard_portal.notification_settings_path
  end

  def developer_portal_home_path(profile)
    PortalPathsHelper.routes.developer_portal.developers_profile_scoped_root_path(developers_profile_scoped: profile)
  end

  def company_portal_home_path(company)
    PortalPathsHelper.routes.company_portal.company_scoped_root_path(company_scoped: company)
  end

  # The Apply form for a job, in the applicant's developer portal.
  def developer_portal_apply_path(profile, job)
    PortalPathsHelper.routes.developer_portal.interactive_record_action_developers_profile_scoped_hiring_job_post_path(
      developers_profile_scoped: profile, id: job, interactive_action: :apply
    )
  end

  def developer_portal_application_path(profile, application)
    PortalPathsHelper.routes.developer_portal.developers_profile_scoped_hiring_job_application_path(
      developers_profile_scoped: profile, id: application
    )
  end

  def company_portal_application_path(company, application)
    PortalPathsHelper.routes.company_portal.company_scoped_hiring_job_application_path(
      company_scoped: company, id: application
    )
  end

  # ?tab= connections, followers, following or suggestions.
  def developer_portal_network_path(profile, tab: nil)
    PortalPathsHelper.routes.developer_portal.developers_profile_scoped_network_path(developers_profile_scoped: profile, tab:)
  end

  def developer_portal_project_path(profile, project)
    PortalPathsHelper.routes.developer_portal.developers_profile_scoped_showcase_project_path(
      developers_profile_scoped: profile, id: project
    )
  end

  def developer_portal_new_project_path(profile)
    PortalPathsHelper.routes.developer_portal.new_developers_profile_scoped_showcase_project_path(developers_profile_scoped: profile)
  end

  # Where a credited developer confirms or declines a project credit.
  def developer_portal_credit_path(profile, contributor)
    PortalPathsHelper.routes.developer_portal.developers_profile_scoped_showcase_project_contributor_path(
      developers_profile_scoped: profile, id: contributor
    )
  end

  def developer_portal_credits_path(profile)
    PortalPathsHelper.routes.developer_portal.developers_profile_scoped_showcase_project_contributors_path(
      developers_profile_scoped: profile
    )
  end

  def developer_portal_edit_profile_path(profile)
    developer_portal_home_path(profile).chomp("/") + "/developers_profile/edit"
  end

  def new_developer_profile_path
    Rails.application.routes.url_helpers.new_developer_profile_setup_path
  end

  # POST here to post a job or gig as yourself (see PersonalPostingsController).
  def post_as_yourself_path
    Rails.application.routes.url_helpers.personal_posting_path
  end

  def new_company_path
    Rails.application.routes.url_helpers.new_company_setup_path
  end
end
