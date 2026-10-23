AdminPortal::Engine.routes.draw do
  root to: "dashboard#index"
  register_resource ::User
  register_resource ::Company
  register_resource ::Admin
  register_resource ::Skill
  register_resource ::Developers::Profile
  register_resource ::Hiring::JobPost
  register_resource ::Hiring::JobApplication
  register_resource ::Showcase::Project
  register_resource ::Showcase::ProjectContributor
  register_resource ::Network::Follow
  register_resource ::Network::Endorsement

  get "credentials", to: "credentials/awards#index", as: :credential_awards
  get "credentials/export", to: "credentials/awards#export", as: :export_credential_awards
  get "credentials/new", to: "credentials/awards#new", as: :new_credential_award
  post "credentials/preview", to: "credentials/awards#preview", as: :preview_credential_awards
  post "credentials", to: "credentials/awards#create"
  get "credentials/batch/new", to: "credentials/awards#batch_new", as: :new_credential_batch
  post "credentials/batch/preview", to: "credentials/awards#batch_preview", as: :preview_credential_batch
  post "credentials/batch", to: "credentials/awards#batch_create", as: :credential_batch
  get "credentials/:id", to: "credentials/awards#show", as: :credential_award
  get "credentials/:id/edit", to: "credentials/awards#edit", as: :edit_credential_award
  patch "credentials/:id", to: "credentials/awards#update"
  post "credentials/:id/revoke", to: "credentials/awards#revoke", as: :revoke_credential_award
  post "credentials/:id/expire", to: "credentials/awards#expire", as: :expire_credential_award
  post "credentials/:id/reissue", to: "credentials/awards#reissue", as: :reissue_credential_award

  # register resources above.

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
end

# mount our app
Rails.application.routes.draw do
  constraints Rodauth::Rails.authenticate(:admin) do
    mount AdminPortal::Engine, at: "/admin"
  end
end
