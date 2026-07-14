require "test_helper"

module Engine
  class SystemPlayerTest < ActiveSupport::TestCase
    def player(depth: SystemPlayer::DEFAULT_DEPTH, seed: 42)
      SystemPlayer.new(depth: depth, rng: Random.new(seed))
    end

    test "takes an immediate winning move" do
      board = Board.blank
      board.set(1, 2, "b") # one step from black's far rank
      board.set(4, 7, "w")
      move = player.choose(board, "b")
      assert_equal [ 0, 2 ], move.to
    end

    test "captures a hanging pawn" do
      board = Board.blank
      board.set(4, 4, "b")
      board.set(3, 3, "w")
      board.set(1, 0, "w")
      move = player.choose(board, "b")
      assert move.capture
      assert_equal [ 3, 3 ], move.to
    end

    test "does not advance onto a defended square" do
      board = Board.blank
      board.set(4, 4, "b") # advancing to e4 hangs to d3
      board.set(2, 3, "w")
      board.set(6, 0, "b") # safe alternative
      move = player.choose(board, "b")
      refute_equal [ 3, 4 ], move.to, "walked onto a defended square"
    end

    test "pushes its runner when it wins the promotion race" do
      board = Board.blank
      board.set(4, 0, "w") # white runner, 3 moves from promoting
      board.set(3, 7, "b") # black runner, 3 moves — black to move wins the race
      move = player.choose(board, "b")
      assert_equal 7, move.from[1], "expected the h-file runner to push"
      assert_equal [ 2, 7 ], move.to
    end

    test "returns nil when the side to move is stuck" do
      board = Board.blank
      board.set(3, 3, "w")
      board.set(4, 3, "b")
      assert_nil player.choose(board, "w")
    end

    test "same seed gives the same move" do
      board = Board.initial
      assert_equal player(seed: 7).choose(board, "b"), player(seed: 7).choose(board, "b")
    end

    test "self-play from the initial position always terminates legally" do
      board = Board.initial
      turn = "w"
      status = "in_progress"
      players = { "w" => player(depth: 3, seed: 1), "b" => player(depth: 3, seed: 2) }
      200.times do
        move = players[turn].choose(board, turn)
        break if move.nil?
        Rules.apply!(board, move.from, move.to)
        status = Rules.status_after(board, turn)
        break unless status == "in_progress"
        turn = Rules.opponent(turn)
      end
      assert_includes %w[white_won black_won draw], status
    end
  end
end
