module Engine
  # Move selection for the computer side: negamax with alpha-beta pruning.
  #
  # Evaluation exploits a property unique to pawns-only play: with no kings,
  # a passed pawn (clear file ahead, no enemy pawns on adjacent files ahead)
  # can never be stopped. Whoever's runner promotes first wins, so the race
  # term dominates everything except a proven mate in the search tree.
  #
  # depth 1 behaves as a greedy player (easy); DEFAULT_DEPTH plays well.
  # Pass a seeded Random for reproducible tie-breaking in tests.
  class SystemPlayer
    WIN = 1_000_000
    DEFAULT_DEPTH = 6

    def initialize(depth: DEFAULT_DEPTH, rng: Random.new)
      @depth = [ depth, 1 ].max
      @rng = rng
    end

    def choose(board, color)
      moves = ordered(Rules.legal_moves(board, color))
      return nil if moves.empty?

      best = nil
      alpha = -Float::INFINITY
      moves.each do |move|
        child = board.dup
        Rules.apply!(child, move.from, move.to)
        score = if Rules.win?(child, color)
          WIN + @depth
        else
          -negamax(child, Rules.opponent(color), @depth - 1, -Float::INFINITY, -alpha)
        end
        if score > alpha
          alpha = score
          best = move
        end
      end
      best
    end

    private

    # Shuffle for variety between equal moves, then search captures first
    # so alpha-beta prunes harder.
    def ordered(moves)
      moves.shuffle(random: @rng).sort_by! { |m| m.capture ? 0 : 1 }
    end

    def negamax(board, color, depth, alpha, beta)
      # The opponent moved last; a completed win ends the line. Subtracting
      # remaining depth makes nearer wins score higher than distant ones.
      return -(WIN + depth) if Rules.win?(board, Rules.opponent(color))

      moves = Rules.legal_moves(board, color)
      return 0 if moves.empty? # draw: side to move is stuck
      return evaluate(board, color) if depth <= 0

      best = -Float::INFINITY
      ordered(moves).each do |move|
        child = board.dup
        Rules.apply!(child, move.from, move.to)
        score = -negamax(child, Rules.opponent(color), depth - 1, -beta, -alpha)
        best = score if score > best
        alpha = score if score > alpha
        break if alpha >= beta
      end
      best
    end

    # Static evaluation from the perspective of the side to move.
    def evaluate(board, color)
      side_score(board, color) - side_score(board, Rules.opponent(color)) +
        race_score(board, color)
    end

    def side_score(board, color)
      board.pawns(color).sum do |rank, file|
        advance = color == Board::WHITE ? rank : Board::SIZE - 1 - rank
        score = 100 + 5 * advance
        score += 40 + 10 * advance if runner?(board, color, rank, file)
        score
      end
    end

    # Both sides having an unstoppable runner is a pure race; the side to
    # move wins ties because it promotes first.
    def race_score(board, color)
      mine = runner_distance(board, color)
      theirs = runner_distance(board, Rules.opponent(color))
      if mine && (theirs.nil? || mine <= theirs)
        WIN / 2 - 1_000 * mine
      elsif theirs
        -(WIN / 2 - 1_000 * theirs)
      else
        0
      end
    end

    # Fewest own moves any unstoppable pawn needs to reach the far rank.
    def runner_distance(board, color)
      board.pawns(color)
           .select { |rank, file| runner?(board, color, rank, file) }
           .map { |rank, _| (Rules.far_rank(color) - rank).abs }
           .min
    end

    # No pawn of either color ahead on this file, and no enemy pawn ahead on
    # an adjacent file: nothing can ever block or capture this pawn.
    def runner?(board, color, rank, file)
      dir = Rules.direction(color)
      enemy = Rules.opponent(color)
      r = rank + dir
      while r.between?(0, Board::SIZE - 1)
        return false unless board.empty_at?(r, file)
        return false if file > 0 && board.at(r, file - 1) == enemy
        return false if file < Board::SIZE - 1 && board.at(r, file + 1) == enemy
        r += dir
      end
      true
    end
  end
end
