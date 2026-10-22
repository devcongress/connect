module Site
  class CompaniesController < BaseController
    def index
      scope = Company.organizations
      @countries = scope.where.not(country: [nil, ""]).distinct.order(:country).pluck(:country)

      scope = scope.search(params[:q]) if params[:q].present?
      scope = scope.where(country: params[:country]) if params[:country].present?

      @companies = paginate(scope.order(:name))
      company_ids = @companies.map(&:id)
      @job_counts = Hiring::JobPost.visible_to(current_user).where(company_id: company_ids).group(:company_id).count
    end

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
