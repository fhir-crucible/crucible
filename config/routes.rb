Rails.application.routes.draw do

  get 'tests/execute_all' => 'tests#execute_all', defaults: { format: :json }
  get 'tests/execute/:title' => 'tests#execute', defaults: { format: :json }
  get 'tests/conformance' => 'tests#conformance', defaults: { format: :json }

  resources :tests, defaults: { format: :json }
  resources :servers do
    get :test
  end

  root to: "home#index"
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # scope :api, module: :api do
  #   devise_for :users, controllers: {
  #     sessions: 'api/sessions',
  #     registrations: 'api/registrations'
  #   }
  # end

  namespace :api, format: :json do
    get 'servers/:id/conformance', to: 'servers#conformance'
    get 'servers/:id/summary', to: 'servers#summary'
    resources :servers
    resources :multiservers
    resources :tests
    resources :test_runs
    get '/test_results/:id/result' => 'test_results#result', defaults: { format: :json }
    get '/summary/latest/:server_id' => 'summaries#show_latest'
    get '/summary/latest' => 'summaries#index_latest'
    get '/aggregate_summary' => 'summaries#index_latest'
    get '/aggregate_summary/:user_id' => 'summaries#index_latest'
    get '/summary/:summary_id' => 'summaries#show'
    get '/summary' => 'summaries#index'
  end

end
