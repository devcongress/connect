module DeveloperPortal
  # The viewer's network: connections, followers, people and companies they
  # follow, and people they may know. Follow actions use the public controllers
  # so the buttons work the same everywhere.
  class NetworkController < PlutoniumController
    TABS = %w[connections followers following companies suggestions].freeze

    def index
      @profile = current_scoped_entity
      @tab = TABS.include?(params[:tab]) ? params[:tab] : "connections"
      @counts = {
        "connections" => @profile.connections.count,
        "followers" => @profile.followers.count,
        "following" => @profile.following.count,
        "companies" => @profile.followed_companies.count
      }
      if @tab == "companies"
        @companies = @profile.followed_companies.merge(::Network::CompanyFollow.newest).to_a
        return
      end

      @people =
        case @tab
        when "connections" then @profile.connections.order(:name)
        when "followers" then @profile.followers.merge(::Network::Follow.newest)
        when "following" then @profile.following.merge(::Network::Follow.newest)
        else @profile.suggested_profiles(limit: 12)
        end
      # Hidden profiles stay out of every list, including your followers.
      @people = @people.merge(::Developers::Profile.visible_to(current_user)).includes(profile_skills: :skill).to_a if @people.respond_to?(:merge)
      @following_ids = @profile.outgoing_follows.pluck(:followee_id).to_set
      @follower_ids = @profile.incoming_follows.pluck(:follower_id).to_set
    end
  end
end
