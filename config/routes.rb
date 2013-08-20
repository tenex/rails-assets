RailsAssets::Application.routes.draw do
  get "/index",     to: "main#list"
  post "/convert",  to: "main#convert"
  get "/api/v1/dependencies", to: "main#dependencies"

  if Rails.env.development?
    root to: "main#home"
  else
    root to: lambda {|_| [200, {}, ["Comming Soon..."]] }
  end
end
