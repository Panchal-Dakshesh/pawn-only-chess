module Api
  class GamesController < BaseController
    def create
      color = params[:user_color].presence || "white"
      unless Game::COLORS.include?(color)
        return render json: { error: "user_color must be white or black" }, status: :bad_request
      end
      render json: Game.start!(user_color: color).state, status: :created
    end

    def show
      render json: Game.find(params[:id]).state
    end

    def restart
      game = Game.find(params[:id])
      game.with_lock { game.restart! }
      render json: game.state
    end
  end
end
