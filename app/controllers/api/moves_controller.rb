module Api
  class MovesController < BaseController
    # Applies the user's move, then the system's reply, in one request.
    def create
      game = Game.find(params[:game_id])
      game.with_lock do
        game.play_user_move!(params.require(:from), params.require(:to))
        game.play_system_move!
      end
      render json: game.state, status: :created
    end
  end
end
