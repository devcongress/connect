class CreateNetworkCompanyFollows < ActiveRecord::Migration[8.1]
  def change
    create_table :network_company_follows do |t|
      t.references :follower, null: false,
        foreign_key: {to_table: :developers_profiles, on_delete: :cascade}
      t.references :company, null: false, foreign_key: {on_delete: :cascade}

      t.timestamps

      t.index %i[follower_id company_id], unique: true
    end
  end
end
