RailsAssets::Application.routes.draw do
  resources :components, only: [:index, :create]

  get "/api/v1/dependencies", to: "main#dependencies"

  if Rails.env.development?
    root to: "main#home"
  else
    get "/home", to: "main#home"
    root to: lambda {|_| [200, {}, ["Comming Soon..."]] }
  end
end
