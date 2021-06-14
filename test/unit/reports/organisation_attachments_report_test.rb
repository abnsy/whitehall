require "test_helper"

class Reports::OrganisationAttachmentsReportTest < ActiveSupport::TestCase
  test "returns a report containing unaccessible attachments for an organisation" do
    organisation = create(:organisation, slug: "best-org", alternative_format_contact_email: "foo@bar.com")
    create(:publication, :published,
            organisations: [organisation],
            alternative_format_provider: organisation,
            attachments: [
              create(:file_attachment, accessible: false)
            ]
          )

    path = nil
    Timecop.freeze do
      path = Rails.root.join("tmp/#{organisation.slug}-attachments_#{Time.zone.now.strftime('%d-%m-%Y_%H-%M')}.csv")

      Reports::OrganisationAttachmentsReport.new(organisation.slug).report
    end

    assert_equal Reports::OrganisationAttachmentsReport::CSV_HEADERS, CSV.read(path)[0]
    assert_equal 1, CSV.read(path, headers: true).count
  end

  test "returns blank report if organisation only contains accessible attachments" do
    publication = create(:publication, :published, :with_file_attachment)
    organisation = publication.organisations.last

    path = nil
    Timecop.freeze do
      path = Rails.root.join("tmp/#{organisation.slug}-attachments_#{Time.zone.now.strftime('%d-%m-%Y_%H-%M')}.csv")

      Reports::OrganisationAttachmentsReport.new(organisation.slug).report
    end

    assert_equal 0, CSV.read(path, headers: true).count
  end
end
