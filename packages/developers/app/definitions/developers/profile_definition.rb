module Developers
  class ProfileDefinition < Developers::ResourceDefinition
    class Display < Plutonium::UI::Display::Resource
      private

      def display_class
        [super, "developer-profile-display"].filter_map(&:presence).join(" ")
      end
    end

    show_page_title "Profile"
    edit_page_title "Edit profile"
    modal false
    submit_and_continue false

    field :bio, as: :markdown
    field :contact_email, as: :email, label: "Contact email"
    field :phone, as: :phone
    field :website_url, as: :url, label: "Website"
    field :github_url, as: :url, label: "GitHub"
    field :linkedin_url, as: :url, label: "LinkedIn"
    field :x_url, as: :url, label: "X (Twitter)"
    field :years_experience, label: "Years of experience"
    field :remote_ok, label: "Open to remote work"
    field :open_to_relocation, label: "Open to relocating"
    field :visibility, label: "Who can see your profile"

    input :other_names, hint: "Middle and last names"
    input :handle, hint: "Your public page will be at /@handle", wrapper: {class: "col-span-full"}
    input :headline, placeholder: "e.g. Backend engineer, Rails and Postgres", wrapper: {class: "col-span-full"},
      hint: "One line on what you do. It shows under your name in the directory and on your profile."
    input :country, as: :slim_select, choices: -> { World.country_names }, placeholder: "Choose a country"
    input :city, hint: "Or the nearest one."
    input :region, label: "Region / state"
    input :bio, hint: "Markdown supported."
    input :timezone, as: :slim_select, choices: -> { ActiveSupport::TimeZone.all.map(&:name) }
    input :remote_ok, as: :toggle
    input :open_to_relocation, as: :toggle
    input :visibility, as: :select,
      choices: [["Everyone: public directory and /@handle page", "everyone"], ["Signed-in members only", "members"], ["Hidden: only you", "hidden"]],
      hint: "Public profiles can be found by companies and search engines."
    input :contact_visibility, as: :select, label: "Who can see your email and phone",
      hint: "Connections are people you follow who follow you back.",
      choices: [["Everyone who can see your profile", "everyone"], ["Signed-in members only", "members"], ["Your connections only", "connections"]]
    input :github_url, placeholder: "https://github.com/you"
    input :linkedin_url, placeholder: "https://linkedin.com/in/you"
    input :website_url, placeholder: "https://"
    input :x_url, placeholder: "https://x.com/you"

    display :bio, wrapper: {class: "col-span-full"}
    display :headline, wrapper: {class: "col-span-full"}

    form_layout do
      section :about, :first_name, :other_names, :handle, :headline, label: "About you", columns: 2
      section :bio, :bio, label: "Bio", description: "A few sentences about what you do and what you're looking for."
      section :work, :availability, :seniority, :years_experience, label: "Work", description: "Let companies know if you're looking.", columns: 3
      section :location, :country, :city, :region, :timezone, :remote_ok, :open_to_relocation, label: "Location", columns: 2
      section :contact, :contact_email, :phone, :website_url, :github_url, :linkedin_url, :x_url, label: "Contact & links", columns: 2
      section :privacy, :visibility, :contact_visibility, label: "Privacy", columns: 2
      ungrouped label: "Other"
    end

    display_layout do
      section :about, :name, :handle, :headline, :bio, label: "About"
      section :work, :availability, :seniority, :years_experience, label: "Work"
      section :location, :country, :city, :region, :timezone, :remote_ok, :open_to_relocation, label: "Location"
      section :contact, :contact_email, :phone, :website_url, :github_url, :linkedin_url, :x_url, label: "Contact & links"
      section :privacy, :visibility, :contact_visibility, label: "Privacy"
      ungrouped label: "Other"
    end
  end
end
