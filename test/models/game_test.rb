require "test_helper"

class GameTest < ActiveSupport::TestCase
  test "start! sets up the initial position with white to move" do
    game = Game.start!
    assert game.id.present?
    assert_equal "in_progress", game.status
    assert_equal "white", game.turn
    assert_equal 8, game.state[:legal_moves].size
    assert_equal Engine::Board.initial.to_s, game.board
  end

  test "start! as black lets the system open the game" do
    game = Game.start!(user_color: "black")
    assert_equal 1, game.moves.count
    assert_equal "white", game.moves.first.color
    assert_equal "black", game.turn
    assert game.user_turn?
  end

  test "a user move is applied, persisted, and answered by the system" do
    game = Game.start!
    game.play_user_move!("e1", "e2")
    game.play_system_move!

    assert_equal 2, game.moves.count
    assert_equal %w[white black], game.moves.map(&:color)
    assert_equal "white", game.turn

    reloaded = Game.find(game.id) # resume
    assert_equal game.board, reloaded.board
    assert_equal 2, reloaded.moves.count
  end

  test "illegal moves are rejected without changing state" do
    game = Game.start!
    before = game.board
    assert_raises(Engine::IllegalMoveError) { game.play_user_move!("e1", "e4") }
    assert_raises(Engine::IllegalMoveError) { game.play_user_move!("e8", "e7") } # not your pawn
    assert_raises(Engine::IllegalMoveError) { game.play_user_move!("e4", "e5") } # no pawn there
    assert_equal before, game.reload.board
    assert_equal 0, game.moves.count
  end

  test "moving out of turn is rejected" do
    game = Game.start!(user_color: "white")
    game.update!(turn: "black")
    assert_raises(Engine::IllegalMoveError) { game.play_user_move!("e1", "e2") }
  end

  test "win is detected and stops further play" do
    game = Game.start!
    game.update!(board: Engine::Board.blank.tap { |b| b.set(6, 0, "w"); b.set(1, 7, "b") }.to_s)
    game.play_user_move!("a7", "a8")
    assert_equal "white_won", game.status
    assert_raises(Engine::IllegalMoveError) { game.play_user_move!("a8", "a8") }
    assert_nil game.play_system_move!
  end

  test "draw is detected when the opponent is left with no moves" do
    game = Game.start!
    board = Engine::Board.blank
    board.set(2, 0, "w") # white will advance to a4...
    board.set(4, 0, "b") # ...leaving this black pawn face-to-face with nowhere to go
    game.update!(board: board.to_s)
    game.play_user_move!("a3", "a4")
    assert_equal "draw", game.status
  end

  test "restart! resets the board but keeps the game id" do
    game = Game.start!
    game.play_user_move!("e1", "e2")
    game.play_system_move!
    id = game.id
    game.restart!
    assert_equal id, game.id
    assert_equal Engine::Board.initial.to_s, game.board
    assert_equal "in_progress", game.status
    assert_equal 0, game.moves.count
  end
end
