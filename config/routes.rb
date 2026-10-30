Rails.application.routes.draw do
  # Health check for load balancers and uptime monitors.
  get "up" => "rails/health#show", as: :rails_health_check

  root "frontend#show"
  get "*path", to: "frontend#show",
    constraints: ->(request) { !request.path.match?(%r{\A/api(/|\z)}) && request.format.html? }
end
