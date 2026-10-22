require "test_helper"

class SitemapTest < ActionDispatch::IntegrationTest
  include AccountsTestHelper

  test "lists what guests can see and nothing else" do
    create_profile!(handle: "pat", visibility: :everyone)
    create_profile!(handle: "momo", visibility: :members)
    hiring = create_company!(name: "Hiring Co")
    quiet = create_company!(name: "Quiet Co")
    job = create_job!(company: hiring, title: "Live Role")
    members_job = create_job!(company: quiet, title: "Members Role", visibility: :members)
    draft = create_job!(company: hiring, published: false)
    filled = create_job!(company: hiring).tap(&:mark_filled!)
    skill = Skill.create!(
      name: "React",
      category: "Frontend",
      description: "React builds component-based interfaces.",
      website_url: "https://react.dev/",
      why_description: "React is useful for complex interfaces.",
      company_examples: [{"name" => "Shopify", "url" => "https://www.shopify.com/"}],
      content_curated: true
    )
    incomplete_skill = Skill.create!(name: "Uncurated tool", category: "Frontend")

    get "/sitemap.xml"

    assert_response :success
    assert_equal "application/xml", response.media_type
    locs = Nokogiri::XML(response.body).remove_namespaces!.xpath("//loc").map(&:text)
    assert_includes locs, "http://www.example.com/"
    assert_includes locs, "http://www.example.com/@pat"
    assert_includes locs, "http://www.example.com/companies/#{hiring.slug}"
    assert_includes locs, "http://www.example.com/jobs/#{job.to_param}"
    assert_includes locs, "http://www.example.com/technical-skills/#{skill.slug}"
    assert_not_includes locs, "http://www.example.com/technical-skills/#{incomplete_skill.slug}"
    assert_not_includes locs, "http://www.example.com/@momo"
    assert_not_includes locs, "http://www.example.com/companies/#{quiet.slug}"
    [members_job, draft, filled].each { |hidden| assert_not_includes locs, "http://www.example.com/jobs/#{hidden.to_param}" }
  end
end
