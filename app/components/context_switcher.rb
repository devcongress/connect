# Topbar dropdown for moving between the places a user can work in:
# their home dashboard, their developer profile, and each company.
class ContextSwitcher < Plutonium::UI::Component::Base
  include PortalPathsHelper

  def initialize(user:, current: nil)
    @user = user
    @current = current
  end

  def view_template
    details(class: "relative group", data: {controller: "dismissable"}) do
      summary(
        class: "flex cursor-pointer list-none items-center gap-2 rounded-[var(--pu-radius-md)] px-2 py-1 " \
               "text-sm font-medium text-[var(--pu-text)] hover:bg-[var(--pu-surface-alt)] [&::-webkit-details-marker]:hidden",
        aria_label: "Switch context"
      ) do
        render_current
        render Phlex::TablerIcons::Selector.new(class: "h-4 w-4 text-[var(--pu-text-muted)]")
      end

      div(
        class: "absolute left-0 z-50 mt-2 w-72 overflow-hidden rounded-[var(--pu-radius-lg)] border border-[var(--pu-border)] " \
               "bg-[var(--pu-surface-raised)] py-1",
        style: "box-shadow: var(--pu-shadow-lg)"
      ) do
        item(label: "Dashboard", sublabel: @user.email, href: dashboard_path, active: @current.nil?) do
          span(class: "inline-flex h-8 w-8 items-center justify-center rounded-full bg-[var(--pu-surface-alt)]") do
            render Phlex::TablerIcons::Home.new(class: "h-4 w-4 text-[var(--pu-text-muted)]")
          end
        end

        heading("Developer profile")
        if (profile = @user.developer_profile)
          item(label: profile.name, sublabel: "@#{profile.handle}", href: developer_portal_home_path(profile), active: @current == profile) do
            render InitialsAvatar.new(name: profile.name, seed: profile.handle, size: :sm)
          end
        else
          create_link("Create developer profile", new_developer_profile_path)
        end

        heading("Companies")
        @user.company_users.includes(:company).sort_by { |m| m.company.display_name }.each do |membership|
          company = membership.company
          item(label: company.to_label, sublabel: membership.role.humanize, href: company_portal_home_path(company), active: @current == company) do
            render InitialsAvatar.new(name: company.display_name, seed: company.slug, size: :sm, shape: :square)
          end
        end
        create_link("Set up a company", new_company_path)
      end
    end
  end

  private

  def render_current
    case @current
    when Developers::Profile
      render InitialsAvatar.new(name: @current.name, seed: @current.handle, size: :sm)
      span(class: "hidden sm:inline truncate max-w-[12rem]") { @current.name }
    when Company
      render InitialsAvatar.new(name: @current.name, seed: @current.slug, size: :sm, shape: :square)
      span(class: "hidden sm:inline truncate max-w-[12rem]") { @current.name }
    else
      render Phlex::TablerIcons::Home.new(class: "h-4 w-4 text-[var(--pu-text-muted)]")
      span(class: "hidden sm:inline") { "Dashboard" }
    end
  end

  def heading(text)
    div(class: "mt-1 border-t border-[var(--pu-border-muted)] px-3 pb-1 pt-2 text-xs font-semibold uppercase tracking-wide text-[var(--pu-text-subtle)]") { text }
  end

  def item(label:, sublabel:, href:, active:, &avatar)
    a(
      href:,
      class: tokens(
        "flex items-center gap-3 px-3 py-2 text-sm hover:bg-[var(--pu-surface-alt)]",
        active ? "bg-[var(--pu-surface-alt)]" : nil
      ),
      aria_current: (active ? "page" : nil)
    ) do
      yield
      span(class: "min-w-0 flex-1") do
        span(class: "block truncate font-medium text-[var(--pu-text)]") { label }
        span(class: "block truncate text-xs text-[var(--pu-text-muted)]") { sublabel }
      end
      render Phlex::TablerIcons::Check.new(class: "h-4 w-4 text-primary-600") if active
    end
  end

  def create_link(label, href)
    a(href:, class: "flex items-center gap-3 px-3 py-2 text-sm text-primary-600 dark:text-primary-400 hover:bg-[var(--pu-surface-alt)]") do
      span(class: "inline-flex h-8 w-8 items-center justify-center rounded-full border border-dashed border-[var(--pu-border-strong)]") do
        render Phlex::TablerIcons::Plus.new(class: "h-4 w-4")
      end
      plain label
    end
  end

  def dashboard_path
    home_dashboard_path
  end
end
