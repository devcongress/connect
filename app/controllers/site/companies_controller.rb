module Site
  class CompaniesController < BaseController
    def show
      @company = Company.find_by!(slug: params[:slug])

      # Personal posting spaces have no company page; their posts live on the
      # person's profile, when the viewer may see it.
      if @company.personal?
        profile = @company.personal_profile
        raise ActiveRecord::RecordNotFound unless profile&.visible_to?(current_user)

        return redirect_to developer_page_path(handle: profile.handle)
      end

      @jobs = Hiring::JobPost.visible_to(current_user).where(company: @company).newest
    end
  end
end
