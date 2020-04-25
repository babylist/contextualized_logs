Rails.application.routes.draw do
  resources :model
  get '/custom_context' => 'custom_context#show'
end
