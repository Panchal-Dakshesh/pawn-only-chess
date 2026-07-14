require "test_helper"

class ApiFlowTest < ActionDispatch::IntegrationTest
  test "full game flow: create, move, resume, restart" do
    post "/api/games", params: { user_color: "white" }, as: :json
    assert_response :created
    game = response.parsed_body
    assert game["id"].present?
    assert_equal "in_progress", game["status"]
    assert_equal 8, game["legal_moves"].size

    post "/api/games/#{game['id']}/moves", params: { from: "e1", to: "e2" }, as: :json
    assert_response :created
    state = response.parsed_body
    assert_equal 2, state["moves"].size, "expected user move plus system reply"
    assert_equal "white", state["turn"]

    get "/api/games/#{game['id']}"
    assert_response :success
    assert_equal state["board"], response.parsed_body["board"]

    post "/api/games/#{game['id']}/restart"
    assert_response :success
    assert_empty response.parsed_body["moves"]
    assert_equal "in_progress", response.parsed_body["status"]
  end

  test "playing as black gets an opening system move" do
    post "/api/games", params: { user_color: "black" }, as: :json
    assert_response :created
    state = response.parsed_body
    assert_equal 1, state["moves"].size
    assert_equal "black", state["turn"]
    assert(state["legal_moves"].all? { |m| m["from"].end_with?("8") })
  end

  test "illegal move returns 422 with a reason" do
    post "/api/games", as: :json
    id = response.parsed_body["id"]
    post "/api/games/#{id}/moves", params: { from: "e1", to: "e4" }, as: :json
    assert_response :unprocessable_entity
    assert_match(/illegal move/, response.parsed_body["error"])
  end

  test "missing params return 400 and unknown game returns 404" do
    post "/api/games", as: :json
    id = response.parsed_body["id"]
    post "/api/games/#{id}/moves", params: { from: "e2" }, as: :json
    assert_response :bad_request

    get "/api/games/nope"
    assert_response :not_found

    post "/api/games", params: { user_color: "purple" }, as: :json
    assert_response :bad_request
  end
end
