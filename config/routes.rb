RailsAssetsApp::Application.routes.draw do
  resources :components, only: [:index, :new, :create] do
    collection do
      get '/:name/rebuild' => 'components#rebuild',
          constraints: { name: /[^\/]+/ }

      get '/:name/:version' => 'components#assets',
          constraints: { version: /[^\/]+/, name: /[^\/]+/ }
    end
  end

  get '/api/v1/dependencies', to: 'main#dependencies'
  resources :donations, only: :create

  require 'sidekiq/web'
  Sidekiq::Web.use(Rack::Auth::Basic) do |user, password|
    [user, password] == [
      'admin', ENV['SIDEKIQ_PASSWORD'] || 'password'
    ]
  end
  mount Sidekiq::Web => '/sidekiq'

  get '/status', to: 'main#status'

  root to: 'main#home'

  resources :ng_templates, only: :show unless Rails.configuration.x.inline_ng_templates

  get '/home', to: redirect('/')
end
