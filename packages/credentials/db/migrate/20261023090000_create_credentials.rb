class CreateCredentials < ActiveRecord::Migration[8.1]
  def change
    create_table :credentials_definitions do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :short_description, null: false
      t.text :description, null: false
      t.text :eligibility_criteria, null: false
      t.text :evidence_requirements, null: false
      t.string :issuing_authority, null: false, default: "DevCongress"
      t.json :approver_roles, null: false, default: ["super_admin", "admin"]
      t.string :criteria_version, null: false
      t.text :lifecycle_rules, null: false
      t.text :does_not_prove, null: false
      t.string :badge_alt_text, null: false
      t.integer :expires_after_months
      t.boolean :active, null: false, default: true

      t.timestamps

      t.index :slug, unique: true
    end

    create_table :credentials_awards do |t|
      t.belongs_to :definition, null: false, foreign_key: {to_table: :credentials_definitions, on_delete: :restrict}
      t.belongs_to :recipient, null: false, foreign_key: {to_table: :developers_profiles, on_delete: :restrict}
      t.string :public_id, null: false
      t.string :recipient_name, null: false
      t.text :evidence_summary, null: false
      t.string :criteria_version, null: false
      t.integer :status, null: false, default: 0
      t.datetime :consented_at
      t.datetime :issued_at
      t.datetime :expires_at
      t.datetime :revoked_at
      t.text :revoked_reason
      t.references :supersedes, foreign_key: {to_table: :credentials_awards, on_delete: :nullify}
      t.references :created_by_admin, null: false, foreign_key: {to_table: :admins, on_delete: :restrict}
      t.references :updated_by_admin, foreign_key: {to_table: :admins, on_delete: :nullify}

      t.timestamps

      t.index :public_id, unique: true
      t.index [:definition_id, :recipient_id], unique: true,
        where: "status IN (0, 1)", name: "index_credentials_awards_on_current_achievement"
      t.index [:status, :created_at]
    end

    create_table :credentials_events do |t|
      t.belongs_to :award, null: false, foreign_key: {to_table: :credentials_awards, on_delete: :cascade}
      t.references :admin, foreign_key: {on_delete: :nullify}
      t.references :user, foreign_key: {on_delete: :nullify}
      t.string :event_type, null: false
      t.text :reason
      t.json :changeset, null: false, default: {}

      t.timestamps

      t.index [:award_id, :created_at]
      t.index [:event_type, :created_at]
    end
  end
end
