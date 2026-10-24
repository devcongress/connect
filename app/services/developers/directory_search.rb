module Developers
  class DirectorySearch
    AVAILABILITIES = %w[looking open].freeze

    def self.call(**) = new(**).call

    def initialize(scope:, query: nil, skill: nil, country: nil, availability: nil, remote: false, has_experience: false)
      @scope = scope
      @query = query
      @skill = skill
      @country = country
      @availability = availability
      @remote = remote
      @has_experience = has_experience
    end

    def call
      scope = @scope
      scope = scope.search(@query) if @query.present?
      scope = with_skill(scope) if @skill || @has_experience
      scope = scope.where(country: @country) if @country.present?
      scope = scope.where(availability: @availability) if AVAILABILITIES.include?(@availability)
      scope = scope.where(remote_ok: true) if @remote
      scope
    end

    private

    def with_skill(scope)
      matching_skills = @skill ? @skill.profile_skills : Developers::ProfileSkill
      matching_skills = matching_skills.joins(:experience_skills) if @has_experience
      scope.where(id: matching_skills.select(:profile_id))
    end
  end
end
