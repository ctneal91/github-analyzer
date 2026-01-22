Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # API endpoints for React frontend
  namespace :api do
    namespace :v1 do
      get "stats", to: "stats#index"
      get "rate_limit", to: "stats#rate_limit"

      resources :events, only: [ :index, :show ]
      resources :actors, only: [ :index ]
      resources :repositories, only: [ :index ]

      namespace :admin do
        post "ingest", to: "admin#ingest"
        post "enrich", to: "admin#enrich"
        post "sync", to: "admin#sync"
      end
    end
  end
end
