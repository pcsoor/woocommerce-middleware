Rails.application.routes.draw do
  get "variations/edit"
  get "variations/update"
  devise_for :users

  root "products#index"

  resource :onboardings, only: [:new, :create]
  resources :products, only: [:index, :edit, :update] do
    resources :variations, only: [:edit, :update]
  end
  get "up" => "rails/health#show", as: :rails_health_check
end
