Rails.application.routes.draw do

  root 'homepage#index'
  
  # products
  resources :products

  post "/products/retire/:id", to: "products#retire", as: "retire_product"
  post "/products/:id/add_to_cart", to: "products#add_to_cart", as: "add_to_cart"

  # categories
  resources :categories, only: [:show, :new, :create] do
    resources :products, only: [:index]
  end

  # reviews
  resources :reviews, only: [:new, :create]
  
  # merchants
  resources :merchants, only: [:show, :index] do
    resources :products, only: [:index]
  end
  get "/auth/github", as: "github_login"
  get "/auth/:provider/callback", to: "merchants#create", as: "auth_callback"
  post "/logout", to: "merchants#logout", as: "logout"

  # orders
  resources :orders, only: [:show, :destroy]
  get "/cart", to: "orders#index", as: "cart"
  get "/order/checkout", to: "orders#checkout", as: "order_checkout"
  get "/order/:id/confirmation", to: "orders#confirmation", as: "order_confirmation" 
  get "/orders/:id/found", to: "orders#found", as: "orders_found"
  get "/orders/search/new", to: "orders#search_form", as: "orders_search_new"
  post "/orders/search", to: "orders#search", as: "orders_search"
  patch "/order/checkout", to: "orders#complete"

  # order_items
  resources :order_items, only: [:update, :destroy]
  post "/order_items/ship/:id", to: "order_items#ship", as: "ship_item"
end
