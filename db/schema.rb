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

ActiveRecord::Schema[8.1].define(version: 2026_07_14_100002) do
  create_table "games", id: :string, force: :cascade do |t|
    t.string "board", null: false
    t.datetime "created_at", null: false
    t.string "status", default: "in_progress", null: false
    t.string "turn", default: "white", null: false
    t.datetime "updated_at", null: false
    t.string "user_color", default: "white", null: false
  end

  create_table "moves", force: :cascade do |t|
    t.boolean "capture", default: false, null: false
    t.string "color", null: false
    t.datetime "created_at", null: false
    t.string "from_sq", null: false
    t.string "game_id", null: false
    t.integer "number", null: false
    t.string "to_sq", null: false
    t.index ["game_id", "number"], name: "index_moves_on_game_id_and_number", unique: true
  end

  add_foreign_key "moves", "games"
end
