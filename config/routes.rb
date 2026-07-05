Rails.application.routes.draw do
  devise_for :users,
             controllers: {
               registrations: "users/registrations"
             }

  authenticated :user do
    root "dashboard#index", as: :authenticated_root
  end

  devise_scope :user do
    root "devise/sessions#new"
  end

  get "/plans", to: "plans#index"

  resources :deposits,    only: [:index, :show, :new, :create]
  resources :investments, only: [:index, :show]
  resources :withdrawals, only: [:index, :show, :new, :create]

  get "/profits",         to: "profits#index"
  get "/wallet_activity", to: "wallet_activities#index"

  namespace :admin do
    root "dashboard#index"

    resources :deposits, only: [:index, :show] do
      member do
        patch :approve
        patch :reject
      end
    end

    resources :withdrawals, only: [:index, :show] do
      member do
        patch :approve
        patch :reject
        patch :complete
      end
    end

    resources :investments, only: [:index]
  end
end