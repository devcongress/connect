require "openssl"

# Chooses the public builders shown on the homepage for one daily rotation.
# A keyed digest gives every profile in a pool a stable ordering without an
# unbounded database random sort or a user-controlled ranking signal.
class HomepageBuilderSelector
  LIMIT = 6
  ROTATION_PERIOD = 1.day
  DIGEST = "SHA256"
  CONTEXT = "homepage-builders"

  def self.call(**) = new(**).call

  def initialize(
    scope: Developers::Profile.visible_to_everyone,
    period: Date.current,
    limit: LIMIT,
    secret: Rails.application.secret_key_base
  )
    @scope = scope
    @period_key = period.to_date.iso8601
    @limit = limit
    @secret = secret
  end

  def call
    preferred_ids = preferred_scope.ids
    fallback_ids = @scope.where.not(id: preferred_ids).ids
    selected_ids = ranked(preferred_ids).first(@limit)
    selected_ids.concat(ranked(fallback_ids).first(@limit - selected_ids.size))

    profiles = @scope.where(id: selected_ids).includes(profile_skills: :skill).index_by(&:id)
    selected_ids.filter_map { |id| profiles[id] }
  end

  private

  def preferred_scope
    @scope.left_joins(:profile_skills, :experiences)
      .where("developers_profile_skills.id IS NOT NULL OR developers_experiences.id IS NOT NULL")
      .distinct
  end

  def ranked(ids)
    ids.sort_by do |id|
      digest = OpenSSL::HMAC.hexdigest(DIGEST, @secret, "#{CONTEXT}:#{@period_key}:#{id}")
      [digest, id]
    end
  end
end
