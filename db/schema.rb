# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_06_21_213330) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "deposits", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "investment_plan_id", null: false
    t.decimal "amount_usd", precision: 12, scale: 2, null: false
    t.decimal "btc_amount", precision: 20, scale: 8, null: false
    t.string "transaction_hash", null: false
    t.integer "status", default: 0, null: false
    t.datetime "submitted_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "approved_at"
    t.datetime "rejected_at"
    t.text "admin_notes"
    t.bigint "reviewed_by_id"
    t.index ["approved_at"], name: "index_deposits_on_approved_at"
    t.index ["investment_plan_id"], name: "index_deposits_on_investment_plan_id"
    t.index ["rejected_at"], name: "index_deposits_on_rejected_at"
    t.index ["reviewed_by_id"], name: "index_deposits_on_reviewed_by_id"
    t.index ["status"], name: "index_deposits_on_status"
    t.index ["transaction_hash"], name: "index_deposits_on_transaction_hash", unique: true
    t.index ["user_id"], name: "index_deposits_on_user_id"
  end

  create_table "investment_plans", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.decimal "investment_amount_usd", precision: 12, scale: 2, null: false
    t.decimal "daily_return_rate", precision: 5, scale: 2, null: false
    t.integer "duration_days", null: false
    t.boolean "active", default: true, null: false
    t.integer "position", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_investment_plans_on_active"
    t.index ["name"], name: "index_investment_plans_on_name", unique: true
    t.index ["position"], name: "index_investment_plans_on_position", unique: true
  end

  create_table "investments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "deposit_id", null: false
    t.bigint "investment_plan_id", null: false
    t.decimal "principal_amount", precision: 12, scale: 2, null: false
    t.decimal "daily_return_rate", precision: 5, scale: 2, null: false
    t.integer "duration_days", null: false
    t.datetime "started_at", null: false
    t.datetime "ends_at", null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "completed_at"
    t.index ["completed_at"], name: "index_investments_on_completed_at"
    t.index ["deposit_id"], name: "index_investments_on_deposit_id", unique: true
    t.index ["ends_at"], name: "index_investments_on_ends_at"
    t.index ["investment_plan_id"], name: "index_investments_on_investment_plan_id"
    t.index ["started_at"], name: "index_investments_on_started_at"
    t.index ["status"], name: "index_investments_on_status"
    t.index ["user_id"], name: "index_investments_on_user_id"
  end

  create_table "profit_records", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "investment_id", null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.date "profit_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["investment_id", "profit_date"], name: "index_profit_records_on_investment_id_and_profit_date", unique: true
    t.index ["user_id"], name: "index_profit_records_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "full_name", default: "", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "role", default: 0, null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  create_table "wallets", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.decimal "available_balance", precision: 20, scale: 8, default: "0.0", null: false
    t.decimal "total_deposited", precision: 20, scale: 8, default: "0.0", null: false
    t.decimal "total_withdrawn", precision: 20, scale: 8, default: "0.0", null: false
    t.decimal "total_profit", precision: 20, scale: 8, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_wallets_on_user_id", unique: true
  end

  create_table "withdrawals", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "reviewer_id"
    t.decimal "amount", precision: 20, scale: 8, null: false
    t.string "btc_address", null: false
    t.integer "status", default: 0, null: false
    t.datetime "requested_at"
    t.datetime "approved_at"
    t.datetime "rejected_at"
    t.datetime "completed_at"
    t.text "admin_notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["reviewer_id"], name: "index_withdrawals_on_reviewer_id"
    t.index ["status"], name: "index_withdrawals_on_status"
    t.index ["user_id"], name: "index_withdrawals_on_user_id"
  end

  add_foreign_key "deposits", "investment_plans"
  add_foreign_key "deposits", "users"
  add_foreign_key "deposits", "users", column: "reviewed_by_id"
  add_foreign_key "investments", "deposits"
  add_foreign_key "investments", "investment_plans"
  add_foreign_key "investments", "users"
  add_foreign_key "profit_records", "investments"
  add_foreign_key "profit_records", "users"
  add_foreign_key "wallets", "users"
  add_foreign_key "withdrawals", "users"
  add_foreign_key "withdrawals", "users", column: "reviewer_id"
end
