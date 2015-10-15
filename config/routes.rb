Rails.application.routes.draw do

  resources :tests, defaults: { format: :json }, only: [ :index ]
  resources :servers, only: [ :show, :create, :update ] do
    resources :testruns, defaults: { format: :json }, only: [ :index, :show, :create ] do
      post 'execute'
      post 'finish'
    end
    get 'conformance', defaults: { format: :json }
    get 'summary', defaults: { format: :json }
    get 'oauth_params', defaults: { format: :json }
    get 'aggregate_run', defaults: { format: :json }
    post 'oauth_params'
  end

  root to: "home#index"

  get 'redirect', to: 'servers#oauth_redirect'

end
