Rails.application.routes.draw do
  mount MagicLamp::Genie, at: "/magic_lamp" if defined?(MagicLamp)

  resources :tests, defaults: { format: :json }, only: [ :index ]
  resources :dashboards, only: [ :show ] do
    get 'results', defaults: {format: :json}
  end
  resources :servers, only: [ :show, :create, :update ] do
    resources :test_runs, defaults: { format: :json }, only: [ :show, :create ] do
      post 'cancel', default: { format: :json }
    end
    get 'conformance', defaults: { format: :json }
    get 'summary', defaults: { format: :json }
    get 'summary_history', defaults: { format: :json }
    get 'oauth_params', defaults: { format: :json }
    get 'aggregate_run', defaults: { format: :json }
    get 'past_runs', defaults: { format: :json }
    get 'supported_tests', defaults: { format: :json }
    post 'oauth_params'
    post 'delete_authorization'
  end

  resources :test_results, only: [:show] do
    get 'reissue_request', default: {format: :json}
  end

  root to: "home#index"
  get 'redirect', to: 'servers#oauth_redirect'

end
