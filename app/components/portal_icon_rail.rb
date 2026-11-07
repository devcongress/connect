# The portal rail's brand returns to the public Connect site. Plutonium's
# default points at the current engine root, which keeps users inside whichever
# account context they are managing.
class PortalIconRail < Plutonium::UI::Layout::IconRail
  include PortalPathsHelper

  private

  def render_brand_section
    div(class: "h-12 flex items-center justify-center border-b border-[var(--pu-border)] shrink-0") do
      next unless brand_slot?

      a(href: public_home_path, aria: {label: "DevCongress Connect home"}, class: "flex items-center justify-center") do
        render brand_slot
      end
    end
  end
end
