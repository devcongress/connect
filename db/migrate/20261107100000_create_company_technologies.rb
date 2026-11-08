class CreateCompanyTechnologies < ActiveRecord::Migration[8.1]
  def change
    create_table :company_technologies do |t|
      t.belongs_to :company, null: false, index: false, foreign_key: {on_delete: :cascade}
      t.belongs_to :skill, null: false, foreign_key: true

      t.timestamps
    end

    add_index :company_technologies, [:company_id, :skill_id], unique: true
  end
end
