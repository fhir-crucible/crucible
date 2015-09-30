Rails.application.routes.draw do

  resources :tests, defaults: { format: :json }
  resources :servers do
    resources :tests do
      post 'execute'
    end
  end

  root to: "home#index"

  namespace :api, format: :json do
    get 'servers/:id/conformance', to: 'servers#conformance'
    get 'servers/:id/summary', to: 'servers#summary'
    post 'servers/:id/generate_summary', to: 'servers#generate_summary'
    put 'servers/:id', to: 'servers#update'
    get 'servers/:id/aggregate_run', to: 'servers#aggregate_run'
    post 'servers/:id/oauth_params', to: 'servers#oauth_params'
    resources :tests
    resources :test_runs
  end

  get 'redirect', to: 'servers#oauth_redirect'

end
