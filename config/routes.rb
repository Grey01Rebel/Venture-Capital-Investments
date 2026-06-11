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

  resources :deposits, only: [:index, :show, :new, :create]
end