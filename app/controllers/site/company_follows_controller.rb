module Site
  # A developer can follow an organization without creating a person-to-person
  # connection or changing access to either developer's profile details.
  class CompanyFollowsController < BaseController
    before_action :require_viewer_profile

    rate_limit to: 30, within: 1.minute, only: :create,
      with: -> { redirect_back_to_company alert: "You're following companies too quickly. Try again in a minute." }

    def create
      viewer_profile.company_follows.find_or_create_by!(company: target_company)
      redirect_back_to_company notice: "You're following #{target_company.display_name}."
    rescue ActiveRecord::RecordInvalid => e
      redirect_back_to_company alert: e.record.errors.full_messages.to_sentence
    end

    def destroy
      viewer_profile.company_follows.where(company: target_company).destroy_all
      redirect_back_to_company notice: "You've unfollowed #{target_company.display_name}."
    end

    private

    def require_viewer_profile
      if current_user.nil?
        redirect_to rodauth(:user).login_path, alert: "Log in to follow companies."
      elsif viewer_profile.nil?
        redirect_to new_developer_profile_path, alert: "Create a developer profile to follow companies."
      end
    end

    def viewer_profile
      current_user&.developer_profile
    end

    def target_company
      @target_company ||= Company.organizations.find_by!(slug: params[:slug])
    end

    def redirect_back_to_company(**flash)
      redirect_back fallback_location: public_company_path(slug: params[:slug]), status: :see_other, **flash
    end
  end
end
