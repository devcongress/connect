module Site
  class DevelopersController < BaseController
    def index
      @selected_skill = Skill.find_by!(slug: params[:skill]) if params[:skill].present?
      scope = Developers::Profile.visible_to(current_user)
      @countries = scope.where.not(country: [nil, ""]).distinct.order(:country).pluck(:country)
      @skills = Skill.joins(profile_skills: :profile).merge(scope).distinct.order(:name).to_a
      @skills = (@skills << @selected_skill).compact.uniq(&:id).sort_by(&:name)

      scope = Developers::DirectorySearch.call(
        scope:,
        query: params[:q],
        skill: @selected_skill,
        country: params[:country],
        availability: params[:availability],
        remote: params[:remote] == "1",
        has_experience: params[:experience] == "1"
      )

      @developers = paginate(scope.includes(profile_skills: :skill).order(availability: :desc, updated_at: :desc))
    end

    def show
      @profile = Developers::Profile.find_by!(handle: params[:handle].to_s.downcase)
      raise ActiveRecord::RecordNotFound unless @profile.visible_to?(current_user)

      @experiences = @profile.experiences.includes(profile_skills: :skill)
      @profile_skills = @profile.profile_skills.includes(:skill).sort_by { |ps| [-ps.endorsements_count, -(ps.years || 0), ps.skill.name] }
      @own = current_user && @profile.user_id == current_user.id
      # Gigs and jobs they've posted as themselves.
      @posts = Hiring::JobPost.visible_to(current_user).joins(:company).where(companies: {personal_owner_id: @profile.user_id}).newest.limit(5)
      # Projects they own or are credited on, that the viewer may see. Owners
      # also see their own hidden projects.
      projects = Showcase::Project.where(id: Showcase::Project.visible_to(current_user).featuring(@profile).select(:id))
      projects = projects.or(Showcase::Project.where(owner: @profile)) if @own
      @projects = projects.includes(:skills, :owner, confirmed_contributors: :profile).newest.limit(12)

      # Network: the viewer's relationship to this person, and their counts.
      @viewer_profile = current_user&.developer_profile
      @following = @viewer_profile&.following?(@profile) || false
      @followed_by = (@viewer_profile && @profile.following?(@viewer_profile)) || false
      @connected = @following && @followed_by
      visible = Developers::Profile.visible_to(current_user)
      @network_counts = {
        followers: @profile.followers.merge(visible).count,
        following: @profile.following.merge(visible).count,
        connections: @profile.connections.merge(visible).count
      }
      @endorsed_skill_ids = @viewer_profile ? @viewer_profile.given_endorsements.where(profile_skill: @profile_skills).pluck(:profile_skill_id).to_set : Set.new
    end
  end
end
