require "test_helper"

module Engine
  class RulesTest < ActiveSupport::TestCase
    test "initial board gives each side exactly eight forward moves" do
      board = Board.initial
      assert_equal 8, Rules.legal_moves(board, "w").size
      assert_equal 8, Rules.legal_moves(board, "b").size
      assert Rules.legal_moves(board, "w").none?(&:capture)
    end

    test "a pawn blocked by any pawn cannot advance" do
      board = Board.blank
      board.set(3, 3, "w")
      board.set(4, 3, "b")
      moves = Rules.legal_moves_from(board, [ 3, 3 ])
      assert_empty moves.reject(&:capture)
    end

    test "captures are diagonal, forward, and only onto enemy pawns" do
      board = Board.blank
      board.set(3, 3, "w")
      board.set(4, 2, "b") # capturable
      board.set(4, 4, "w") # own pawn: not capturable
      board.set(2, 2, "b") # behind: not capturable
      captures = Rules.legal_moves_from(board, [ 3, 3 ]).select(&:capture)
      assert_equal [ [ 4, 2 ] ], captures.map(&:to)
    end

    test "edge-file pawn only has one capture direction" do
      board = Board.blank
      board.set(3, 0, "w")
      board.set(4, 1, "b")
      captures = Rules.legal_moves_from(board, [ 3, 0 ]).select(&:capture)
      assert_equal [ [ 4, 1 ] ], captures.map(&:to)
    end

    test "move! rejects diagonal steps, double steps, backward steps, and occupied squares" do
      board = Board.blank
      board.set(3, 3, "w")
      board.set(4, 4, "b")
      assert_raises(IllegalMoveError) { Rules.move!(board, [ 3, 3 ], [ 4, 4 ]) } # diagonal
      assert_raises(IllegalMoveError) { Rules.move!(board, [ 3, 3 ], [ 5, 3 ]) } # double
      assert_raises(IllegalMoveError) { Rules.move!(board, [ 3, 3 ], [ 2, 3 ]) } # backward
      board.set(4, 3, "b")
      assert_raises(IllegalMoveError) { Rules.move!(board, [ 3, 3 ], [ 4, 3 ]) } # occupied
    end

    test "kill! rejects empty destinations and own pawns" do
      board = Board.blank
      board.set(3, 3, "w")
      board.set(4, 4, "w")
      assert_raises(IllegalMoveError) { Rules.kill!(board, [ 3, 3 ], [ 4, 2 ]) } # empty
      assert_raises(IllegalMoveError) { Rules.kill!(board, [ 3, 3 ], [ 4, 4 ]) } # own pawn
    end

    test "apply! dispatches to advance or capture and mutates the board" do
      board = Board.blank
      board.set(1, 4, "w")
      board.set(2, 5, "b")

      move = Rules.apply!(board, [ 1, 4 ], [ 2, 4 ])
      refute move.capture
      assert_equal "w", board.at(2, 4)

      move = Rules.apply!(board, [ 2, 4 ], [ 3, 4 ])
      refute move.capture
      board.set(4, 5, "b")
      move = Rules.apply!(board, [ 3, 4 ], [ 4, 5 ])
      assert move.capture
      assert_equal "w", board.at(4, 5)
      assert_equal 1, board.count("b")
    end

    test "win by reaching the far rank" do
      board = Board.blank
      board.set(7, 0, "w")
      board.set(3, 3, "b")
      assert Rules.win?(board, "w")
      refute Rules.win?(board, "b")

      board = Board.blank
      board.set(0, 7, "b")
      board.set(3, 3, "w")
      assert Rules.win?(board, "b")
    end

    test "win by capturing every enemy pawn" do
      board = Board.blank
      board.set(3, 3, "w")
      assert Rules.win?(board, "w")
    end

    test "draw when the side to move has no legal move" do
      board = Board.blank
      board.set(3, 3, "w")
      board.set(4, 3, "b")
      assert Rules.draw?(board, "w")
      assert Rules.draw?(board, "b")

      board.set(4, 4, "b") # now white has a capture
      refute Rules.draw?(board, "w")
    end

    test "status_after reports winner, draw, or in_progress" do
      board = Board.blank
      board.set(7, 0, "w")
      board.set(5, 5, "b")
      assert_equal "white_won", Rules.status_after(board, "w")

      board = Board.blank
      board.set(3, 3, "w")
      board.set(4, 3, "b")
      assert_equal "draw", Rules.status_after(board, "w")

      assert_equal "in_progress", Rules.status_after(Board.initial, "w")
    end

    test "board serialization round-trips" do
      board = Board.initial
      Rules.apply!(board, [ 0, 4 ], [ 1, 4 ])
      assert_equal board.to_s, Board.from_s(board.to_s).to_s
    end

    test "square parsing and naming" do
      assert_equal [ 1, 4 ], Board.parse("e2")
      assert_equal "e2", Board.square_name(1, 4)
      assert_raises(IllegalMoveError) { Board.parse("j9") }
    end
  end
end
