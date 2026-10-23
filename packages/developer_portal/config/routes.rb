DeveloperPortal::Engine.routes.draw do
  root to: "dashboard#index"
  # Nested routes are declared explicitly: a profile also has followers,
  # following and endorsers, and those must not get portal routes.
  register_resource ::Developers::Profile, singular: true, associations: %i[experiences profile_skills]
  register_resource ::Developers::Experience
  register_resource ::Developers::ProfileSkill, associations: []
  register_resource ::Hiring::JobPost, associations: []
  register_resource ::Hiring::JobApplication, associations: []
  register_resource ::Showcase::Project, associations: %i[contributors]
  register_resource ::Showcase::ProjectContributor

  # Followers, following, connections and suggestions.
  get "network", to: "network#index", as: :network
  get "credentials", to: "credentials/awards#index", as: :credential_awards
  get "credentials/:id", to: "credentials/awards#show", as: :credential_award,
    constraints: {id: /[1-9A-HJ-NP-Za-km-z]{24}/}
  post "credentials/:id/accept", to: "credentials/awards#accept", as: :accept_credential_award,
    constraints: {id: /[1-9A-HJ-NP-Za-km-z]{24}/}

  # register resources above.

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
end

# mount our app
Rails.application.routes.draw do
  constraints Rodauth::Rails.authenticate(:user) do
    mount DeveloperPortal::Engine, at: "/developer"
  end
end
