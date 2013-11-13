RailsAssets::Application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  resources :components, only: [:index, :new, :create] do
    collection do
      get '/:name/:version' => 'components#assets', constraints: { version: /[^\/]+/ }
    end
  end

  get "/api/v1/dependencies", to: "main#dependencies"

  require 'sidekiq/web'
  Sidekiq::Web.use(Rack::Auth::Basic) do |user, password|
    [user, password] == [
      "admin", ENV['SIDEKIQ_PASSWORD'] || "password"
    ]
  end
  mount Sidekiq::Web => '/sidekiq'

  root to: "main#home"
  get '/home', to: redirect('/')

  match '(errors)/:status', to: 'errors#show',
    constraints: { status: /\d{3}/ },
    defaults: { status: '500' },
    via: :all
end
