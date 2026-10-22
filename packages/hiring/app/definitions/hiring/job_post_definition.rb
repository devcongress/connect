module Hiring
  class JobPostDefinition < Hiring::ResourceDefinition
    modal false
    submit_and_continue false
    index_page_title "Posts"

    action :publish, interaction: Hiring::PublishJobPostInteraction, category: :primary
    action :approve, interaction: Hiring::ApproveJobPostInteraction, category: :primary
    action :decline, interaction: Hiring::DeclineJobPostInteraction, modal: :centered
    action :apply, interaction: Hiring::ApplyToJobInteraction, category: :primary, modal: :centered
    action :renew, interaction: Hiring::RenewJobPostInteraction
    action :mark_filled, interaction: Hiring::MarkJobPostFilledInteraction, confirmation: "Mark this as filled? It will stop being listed."
    action :reopen, interaction: Hiring::ReopenJobPostInteraction
    action :archive, interaction: Hiring::ArchiveJobPostInteraction, category: :danger,
      confirmation: "Archive this post? It will be hidden and can't be edited."

    field :description, as: :markdown
    field :apply_url, as: :url, label: "Application link"
    field :pay, label: "Pay"
    field :timing, label: "Duration"
    field :type_label, label: "Type"

    display :status, as: :badge
    column :status, as: :badge
    column :expires_at, as: :date, label: "Expires"
    display :published_at, as: :date, label: "Published"
    display :expires_at, as: :date, label: "Expires"
    display :description, wrapper: {class: "col-span-full"}
    display :title, wrapper: {class: "col-span-full"}

    input :title, placeholder: "e.g. Senior Backend Engineer, or Landing page for a bakery",
      wrapper: {class: "col-span-full"}
    input :description,
      hint: "Help people decide whether to apply. Cover the work, outcomes, requirements, team, and what success looks like." do |field|
      render Forms::JobDescriptionInput.new(field:)
    end
    # Changing the type re-renders the form: timing fields show for gigs,
    # contracts and internships, and internships can be marked unpaid.
    input :employment_type, label: "Type", as: :select, pre_submit: true,
      choices: ::Hiring::JobPost::TYPE_LABELS.map { |value, label| [label, value] }
    input :duration, placeholder: "e.g. 2 weeks, 3 months", hint: "Roughly how long the work lasts.",
      condition: -> { object.time_bound? }
    input :starts_on, label: "Start date", hint: "Leave blank for \"as soon as possible\".",
      condition: -> { object.time_bound? }
    input :remote_ok, as: :toggle, label: "Remote OK", hint: "People can do this from anywhere.",
      wrapper: {class: "col-span-full"}
    input :country, as: :slim_select, choices: -> { World.country_names }, placeholder: "Choose a country",
      hint: "Where the work is, or where the company is if it's remote."
    input :city, hint: "Leave blank if it doesn't matter."
    input :paid, as: :toggle, label: "This internship is paid", pre_submit: true,
      condition: -> { object.internship? }, wrapper: {class: "col-span-full"}
    # The amounts show the chosen currency as a prefix; picking a currency
    # re-renders the form so the prefix follows.
    input :salary_currency, label: "Currency", as: :slim_select, choices: -> { World.currency_codes },
      pre_submit: true, condition: -> { object.paid? }
    input :pay_period, label: "Paid", as: :select,
      choices: ::Hiring::JobPost::PAY_PERIOD_LABELS.map { |value, label| [label.capitalize, value] },
      condition: -> { object.paid? }
    input :salary_min, label: "Pay from", as: :currency, unit: :salary_currency, step: 1,
      hint: "The lowest you'll pay, or the exact amount.", condition: -> { object.paid? }
    input :salary_max, label: "Pay up to", as: :currency, unit: :salary_currency, step: 1,
      hint: "Leave blank to show a single amount.", condition: -> { object.paid? }
    input :accepts_applications, as: :toggle, label: "Accept applications here",
      hint: "Developers apply with their profile. You review them under Applicants."
    input :apply_url, placeholder: "https://", hint: "Or send people to your own careers page. You can use both."
    input :visibility, as: :select, label: "Who can see this post",
      choices: [["Everyone: public jobs board, shareable link", "everyone"], ["Signed-in members only", "members"]]
    display :visibility, label: "Visible to"

    search do |scope, query|
      scope.where("hiring_job_posts.title LIKE :q OR hiring_job_posts.description LIKE :q", q: "%#{query}%")
    end

    default_sort :created_at, :desc

    # Room for the description beside the status panel.
    display_width :full
    metadata :status, :visibility, :published_at, :expires_at

    form_layout do
      # On edit the type is locked (see the policy), so it's named in the heading instead.
      section :role, :title, :employment_type, :seniority, columns: 2,
        label: ->(form) { form.object.persisted? ? "What you're posting: #{form.object.type_label}" : "What you're posting" },
        description: ->(form) { "The type can't be changed after a post is created." if form.object.persisted? }
      section :description, :description, label: "Description"
      # Hidden as a whole for permanent roles; hiding only its fields would
      # leave an empty heading behind.
      section :timing, :duration, :starts_on, label: "Timing", columns: 2,
        condition: -> { object.time_bound? }
      section :location, :remote_ok, :country, :city, label: "Location", columns: 2
      section :pay, :paid, :salary_currency, :pay_period, :salary_min, :salary_max, label: "Pay",
        description: "Optional, but posts that list pay get more applicants.", columns: 2
      section :applying, :accepts_applications, :apply_url, label: "How to apply", columns: 2
      section :visibility, :visibility, label: "Visibility"
      ungrouped label: "Other"
    end

    display_layout do
      section :overview, :title, :company, :type_label, :seniority, :location, :timing, :pay, label: "Overview"
      section :description, :description, label: "Description"
      section :applying, :accepts_applications, :apply_url, label: "How to apply"
      ungrouped label: "Other"
    end
  end
end
