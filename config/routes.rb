Rails.application.routes.draw do
  devise_for :users

  root "products#index"
  
  resource :onboardings, only: [:new, :create]
  get "up" => "rails/health#show", as: :rails_health_check
end
