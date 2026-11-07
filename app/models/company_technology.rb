# == Schema Information
#
# Table name: company_technologies
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  company_id :integer          not null
#  skill_id   :integer          not null
#
# Indexes
#
#  index_company_technologies_on_company_id_and_skill_id  (company_id,skill_id) UNIQUE
#  index_company_technologies_on_skill_id                 (skill_id)
#
# Foreign Keys
#
#  company_id  (company_id => companies.id) ON DELETE => cascade
#  skill_id    (skill_id => skills.id)
#
class CompanyTechnology < ::ResourceRecord
  belongs_to :company
  belongs_to :skill

  validates :skill, uniqueness: {scope: :company_id}
end
