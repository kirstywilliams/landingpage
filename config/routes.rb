Rails.application.routes.draw do
  match '/interested', to: "home#interested", via: :post
  match "/dispatch_email", to: "home#dispatch_email", as: "dispatch_email", via: :post

  root 'home#index'
end
