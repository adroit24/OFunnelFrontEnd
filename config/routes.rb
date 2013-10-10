OFunnel::Application.routes.draw do

  get "hootsuite/index"

  get "hootshuite/index"

  resources :users
  resources :requests
  resources :groups
  namespace :admin do
    resources :groups
    match 'import_companies' => "groups#import_companies", :as => :import_companies
    root :to => "groups#admin_index"
  end

  get "/linkedin/authorize_with_likedin" => "linkedin#authorize_with_likedin", :as => :authorize_with_likedin
  get "/linkedin/linkedin_authorization_callback" => "linkedin#linkedin_authorization_callback"
  match 'search_connections' => "linkedin#search_connections", :as => :search_connections
  match 'linkedin_search' => "linkedin#linkedin_search", :as => :linkedin_search
  match 'connections/:id/:status' => "linkedin#connections", :as => :connections
  match 'get_people_in_company' => "linkedin#get_people_in_company", :as => :get_people_in_company
  match 'get_people_for_query' => "linkedin#get_people_for_query", :as => :get_people_for_query
  match 'multiple_company_search' => "linkedin#multiple_company_search", :as => :multiple_company_search
  match 'multiple_company_search_results' => "linkedin#multiple_company_search_results", :as => :multiple_company_search_results
  match 'remove_company' => "linkedin#remove_company", :as => :remove_company
  match 'discover_relationships' => "linkedin#discover_relationships", :as => :discover_relationships
  match 'add_relationships' => "linkedin#add_relationships", :as => :add_relationships
  match 'remove_relationship' => "linkedin#remove_relationship", :as => :remove_relationship
  match 'alerts_import_csv' => "linkedin#alerts_import_csv", :as => :alerts_import_csv
  match 'add_recipients' => "linkedin#add_recipients", :as => :add_recipients
  match 'remove_recipient' => "linkedin#remove_recipient", :as => :remove_recipient

  get "/google/authorize_with_google" => "google#authorize_with_google", :as => :authorize_with_google
  get "/google/google_authorization_callback" => "google#google_authorization_callback"

  get "/facebook/authorize_with_facebook" => "facebook#authorize_with_facebook", :as => :authorize_with_facebook
  get "/facebook/facebook_authorization_callback" => "facebook#facebook_authorization_callback"

  get "/salesforce/authorize_with_salesforce" => "salesforce#authorize_with_salesforce", :as => :authorize_with_salesforce
  get "/salesforce/salesforce_authorization_callback" => "salesforce#salesforce_authorization_callback"
  match '/salesforce/explore_relationship' => "salesforce#explore_relationship", :as => :salesforce_explore_relationship
  match '/salesforce/show_more' => "salesforce#show_more", :as => :salesforce_show_more
  match '/salesforce/add_salesforce_connection' => "salesforce#add_salesforce_connection", :as => :add_salesforce_connection
  match '/salesforce/mark_connected' => "salesforce#mark_connected", :as => :salesforce_mark_connected
  match '/salesforce/import_salesforce' => "salesforce#import_salesforce", :as => :import_salesforce

  match '/hootsuite' => "hootsuite#index", :as => :hootsuite
  match '/hootsuite/session_init' => "hootsuite#session_init", :as => :hootsuite_session_init
  match '/hootsuite/authorize' => "hootsuite#authorize", :as => :hootsuite_authorize
  match '/hootsuite/authorize_callback' => "hootsuite#authorize_callback", :as => :hootsuite_authorize_callback
  match '/hootsuite/stream' => "hootsuite#stream", :as => :hootsuite_stream

  get "/twitter/authorize_with_twitter" => "twitter#authorize_with_twitter"
  get "/twitter/twitter_authorization_callback" => "twitter#twitter_authorization_callback"
  match 'twitter_login' => "twitter#index", :as => :twitter_login
  match '/twitter/show/:id' => "twitter#show", :as => :twitter_show

  match 'new_open_request' => "requests#new_open_request", :as => :new_open_request
  match 'request_more_info/:id' => "requests#more_info", :as => :more_info
  match 'accept' => "requests#accept", :as => :accept
  match 'ignore' => "requests#ignore", :as => :ignore
  match 'update_request_info' => "requests#update_request_info", :as => :update_request_info

  match '/logout' => "users#logout", :as => :logout
  match '/connections_strength/:user_name' => "users#connections_strength", :as => :connections_strength
  match '/update_connections_strength' => "users#update_connections_strength", :as => :update_connections_strength
  match '/alerts' => "users#alerts", :as => :alerts
  match '/add_to_salesforce' => "users#add_to_salesforce", :as => :add_to_salesforce
  match '/all_alerts/:id/:type' => "users#all_alerts", :as => :all_alerts

  match '/group_members/:id' => "groups#members", :as => :group_members
  match '/add_group' => "groups#add", :as => :add_group
  match '/delete_group/:id' => "groups#delete", :as => :delete_group
  match '/add_member' => "groups#add_member", :as => :add_member
  match '/add_admin' => "groups#add_admin", :as => :add_admin
  match '/approve_membership/:status/:invite_id/:token' => "groups#approve_membership", :as => :approve_membership
  match '/groups/:tag_id/join' => "groups#join_login_bypass", :as => :join_login_bypass
  match '/groups/join/:invite_id/:token' => "groups#join", :as => :join_group
  match '/group_request' => "groups#group_request", :as => :group_request
  match '/search_group' => "groups#search_group", :as => :search_group
  match '/search_member_in_group' => "groups#search_member_in_group", :as => :search_member_in_group
  match 'groups/import_csv' => "groups#import_csv", :as => :groups_import_csv
  match 'groups/invite_imported_members' => "groups#invite_imported_members", :as => :invite_imported_members

  root :to => "linkedin#index"
  #root :to => "twitter#login_with_twitter"

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
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

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
