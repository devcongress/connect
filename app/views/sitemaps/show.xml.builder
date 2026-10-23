xml.instruct!
xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9" do
  [root_url, developers_directory_url, public_companies_url, public_jobs_url, public_projects_url].each do |url|
    xml.url { xml.loc url }
  end

  entries = @profiles.map { |profile| [developer_page_url(handle: profile.handle), profile.updated_at] } +
    @companies.map { |company| [public_company_url(company.slug), company.updated_at] } +
    @jobs.map { |job| [public_job_url(job), job.updated_at] } +
    @projects.map { |project| [public_project_url(project.slug), project.updated_at] } +
    @skills.map { |skill| [technical_skill_url(skill), skill.updated_at] }

  entries.each do |url, updated_at|
    xml.url do
      xml.loc url
      xml.lastmod updated_at.to_date.iso8601
    end
  end
end
