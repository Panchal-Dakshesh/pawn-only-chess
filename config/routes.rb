Rails.application.routes.draw do
  root "pages#home"

  namespace :api, defaults: { format: :json } do
    resources :games, only: %i[create show] do
      member { post :restart }
      resources :moves, only: :create
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
