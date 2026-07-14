module Api
  class BaseController < ActionController::API
    rescue_from ActiveRecord::RecordNotFound do
      render json: { error: "game not found" }, status: :not_found
    end

    rescue_from Engine::IllegalMoveError do |error|
      render json: { error: error.message }, status: :unprocessable_entity
    end

    rescue_from ActionController::ParameterMissing do |error|
      render json: { error: error.message }, status: :bad_request
    end
  end
end
