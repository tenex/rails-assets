RailsAssets::Application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  resources :components, only: [:index, :new, :create]

  get "/api/v1/dependencies", to: "main#dependencies"

  root to: "main#home"
  get '/home', to: redirect('/')
end
