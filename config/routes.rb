Rails.application.routes.draw do
  # Health check for load balancers and uptime monitors.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    resource :session, only: %i[show create destroy]
    resources :employees, only: %i[index show create update] do
      resources :salary_revisions, only: %i[create]
    end
    resource :filter_options, only: %i[show]
  end

  root "frontend#show"
  get "*path", to: "frontend#show",
    constraints: ->(request) { !request.path.match?(%r{\A/api(/|\z)}) && request.format.html? }
end
