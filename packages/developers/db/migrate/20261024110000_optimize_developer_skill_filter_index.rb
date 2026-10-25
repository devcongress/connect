class OptimizeDeveloperSkillFilterIndex < ActiveRecord::Migration[8.1]
  def change
    remove_index :developers_profile_skills, name: :index_developers_profile_skills_on_profile_id_and_skill_id
    remove_index :developers_profile_skills, name: :index_developers_profile_skills_on_skill_id

    add_index :developers_profile_skills, [:skill_id, :profile_id], unique: true
  end
end
