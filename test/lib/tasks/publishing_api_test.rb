require "test_helper"

class PublishingApiRake < ActiveSupport::TestCase
  extend Minitest::Spec::DSL

  teardown do
    task.reenable if defined?(task) # without this, calling `invoke` does nothing after first test
  end

  describe "#publish_special_routes" do
    let(:task) { Rake::Task["publishing_api:publish_special_routes"] }

    test "publishes each special route" do
      Timecop.freeze do
        params = {
          format: "special_route",
          publishing_app: "whitehall",
          rendering_app: Whitehall::RenderingApp::WHITEHALL_FRONTEND,
          update_type: "major",
          type: "prefix",
          public_updated_at: Time.zone.now.iso8601,
        }

        special_routes.each do |route|
          GdsApi::PublishingApi::SpecialRoutePublisher
            .any_instance.expects(:publish).with(params.merge(route))
        end

        task.invoke
      end
    end
  end

  describe "#publish_redirect_routes" do
    let(:task) { Rake::Task["publishing_api:publish_redirect_routes"] }

    test "publishes each redirect route" do
      Timecop.freeze do
        redirect_routes.each do |route|
          params = {
            base_path: route[:base_path],
            document_type: "redirect",
            schema_name: "redirect",
            locale: "en",
            details: {},
            redirects: [
              {
                path: route[:base_path],
                type: route.fetch(:type, "prefix"),
                destination: route[:destination],
              },
            ],
            publishing_app: "whitehall",
            public_updated_at: Time.zone.now.iso8601,
            update_type: "major",
          }

          GdsApi::PublishingApi
            .any_instance.expects(:put_content).with(route[:content_id], params)

          GdsApi::PublishingApi
            .any_instance.expects(:publish).with(route[:content_id])
        end

        task.invoke
      end
    end
  end

  describe "#republish_all_about_pages" do
    let(:task) { Rake::Task["publishing_api:republish_all_about_pages"] }

    test "republishes all about pages" do
      corporate_info = create(
        :published_corporate_information_page,
        corporate_information_page_type_id: CorporateInformationPageType::AboutUs.id,
      )

      PublishingApiDocumentRepublishingWorker.any_instance.expects(:perform).with(
        corporate_info.document_id,
        true,
      )

      task.invoke
    end
  end

  describe "#republish_*" do
    tasks = [
      { name: "republish_organisation", model: "Organisation" },
      { name: "republish_person", model: "Person" },
      { name: "republish_role", model: "Role" },
    ]

    test "republishes record by slug" do
      tasks.each do |task|
        record = create!(task[:model].underscore)
        model = task[:model].constantize

        model.any_instance.expects(:publish_to_publishing_api)

        task = Rake::Task["publishing_api:#{task[:name]}"]
        task.invoke(record.slug)
        task.reenable
      end
    end
  end

  describe "#republish_all_*" do
    tasks = [
      { name: "republish_all_organisations", model: "Organisation" },
      { name: "republish_all_take_part_pages", model: "TakePartPage" },
      { name: "republish_all_people", model: "Person" },
      { name: "republish_all_roles", model: "Role" },
      { name: "republish_all_role_appointments", model: "RoleAppointment" },
    ]

    test "republishes all records of a model" do
      tasks.each do |task|
        create!(task[:model].underscore)
        model = task[:model].constantize

        model.any_instance.expects(:publish_to_publishing_api).at_least_once

        task = Rake::Task["publishing_api:#{task[:name]}"]
        task.invoke
        task.reenable
      end
    end
  end

  describe "#republish_document" do
    let(:task) { Rake::Task["publishing_api:republish_document"] }

    test "republishes document to Publishing API from slug" do
      document = create(:document)
      PublishingApiDocumentRepublishingWorker.any_instance.expects(:perform).with(document.id)
      task.invoke(document.slug)
    end
  end

  describe "#patch_organisation_links" do
    let(:task) { Rake::Task["publishing_api:patch_organisation_links"] }

    test "patches links for organisations" do
      Whitehall::PublishingApi.expects(:patch_links).with(
        create(:organisation), bulk_publishing: true
      )
      task.invoke
    end
  end

  describe "#patch_published_item_links" do
    let(:task) { Rake::Task["publishing_api:patch_published_item_links"] }

    test "patches links for published editions" do
      edition = create(:edition, :published)
      PublishingApiLinksWorker.expects(:perform_async).with(edition.id)
      task.invoke
    end
  end

  describe "#patch_withdrawn_item_links" do
    let(:task) { Rake::Task["publishing_api:patch_withdrawn_item_links"] }

    test "sends withdrawn item links to Publishing API" do
      edition = create(:edition, :withdrawn)
      PublishingApiLinksWorker.expects(:perform_async).with(edition.id)
      task.invoke
    end
  end

  describe "#patch_draft_item_links" do
    let(:task) { Rake::Task["publishing_api:patch_draft_item_links"] }

    test "sends draft item links to Publishing API" do
      edition = create(:edition)
      PublishingApiLinksWorker.expects(:perform_async).with(edition.id)
      task.invoke
    end
  end

  describe "#publishing_api_patch_links_by_type" do
    let(:task) { Rake::Task["publishing_api:patch_draft_item_links"] }

    test "sends item links to Publishing API from document type" do
      edition = create(:publication)
      PublishingApiLinksWorker.expects(:perform_async).with(edition.id)
      task.invoke("Publication")
    end
  end

  describe "#bulk_republish" do
    describe "#republish_editions_with_attachments" do
      let(:task) { Rake::Task["publishing_api:bulk_republish:republish_editions_with_attachments"] }

      test "republishes all editions with attachments" do
        edition = create(:publication, :published, :with_file_attachment)

        PublishingApiDocumentRepublishingWorker.expects(:perform_async_in_queue).with(
          "bulk_republishing",
          edition.document_id,
          true,
        )
        task.invoke
      end
    end

    describe "#republish_html_attachments" do
      let(:task) { Rake::Task["publishing_api:bulk_republish:republish_html_attachments"] }

      test "republishes all documents with HMTL attachments" do
        edition = create(:publication, :published, :with_html_attachment)

        PublishingApiDocumentRepublishingWorker.expects(:perform_async_in_queue).with(
          "bulk_republishing",
          edition.document_id,
          true,
        )
        task.invoke
      end
    end

    describe "#document_type" do
      let(:task) { Rake::Task["publishing_api:bulk_republish:document_type"] }

      test "republishes all documents from document type" do
        edition = create(:publication)

        PublishingApiDocumentRepublishingWorker.expects(:perform_async_in_queue).with(
          "bulk_republishing",
          edition.document_id,
          true,
        )
        task.invoke("Publication")
      end
    end

    describe "#for_organisation" do
      let(:org) { create(:organisation) }
      let(:task) { Rake::Task["publishing_api:bulk_republish:for_organisation"] }

      test "Republishes the latest edition for each document owned by the organisation" do
        edition = create(:published_news_article, organisations: [org])

        PublishingApiDocumentRepublishingWorker.expects(:perform_async_in_queue).with(
          "bulk_republishing",
          edition.document.id,
          true,
        )

        task.invoke(org.slug)
      end

      test "Ignores documents owned by other organisation" do
        some_other_org = create(:organisation)
        edition = create(:published_news_article, organisations: [some_other_org])

        PublishingApiDocumentRepublishingWorker.expects(:perform_async_in_queue).with(
          "bulk_republishing",
          edition.document.id,
          true,
        ).never

        task.invoke(org.slug)
      end
    end

    describe "#republish_documents_by_content_ids" do
      let(:task) { Rake::Task["publishing_api:bulk_republish:republish_documents_by_content_ids"] }

      test "Republishes documents by content ids" do
        edition = create(:publication)

        PublishingApiDocumentRepublishingWorker.expects(:perform_async_in_queue).with(
          "bulk_republishing",
          edition.document.id,
          true,
        )

        task.invoke([edition.content_id])
      end
    end

    describe "#republish_documents_by_content_ids_from_csv" do
      let(:task) { Rake::Task["publishing_api:bulk_republish:republish_documents_by_content_ids_from_csv"] }
      let(:edition) { create(:publication) }
      let(:filename) { "content_ids_#{Time.zone.now.to_i}" }

      setup do
        File.open("lib/tasks/#{filename}.csv", "w+")
        CSV.open("lib/tasks/#{filename}.csv", "wb") do |csv|
          csv << %w[content_id]
          csv << [edition.content_id]
        end
      end

      after do
        File.delete("lib/tasks/#{filename}.csv") if File.exist?("lib/tasks/#{filename}.csv")
      end

      test "Republishes documents by content ids from csv" do
        PublishingApiDocumentRepublishingWorker.expects(:perform_async_in_queue).with(
          "bulk_republishing",
          edition.document.id,
          true,
        )

        task.invoke(filename)
      end
    end

    describe "#all" do
      let(:task) { Rake::Task["publishing_api:bulk_republish:all"] }

      test "Republishes all documents" do
        publication = create(:published_publication)
        news_story = create(:published_news_story)

        PublishingApiDocumentRepublishingWorker.expects(:perform_async_in_queue).with(
          "bulk_republishing",
          news_story.document_id,
          true,
        )

        PublishingApiDocumentRepublishingWorker.expects(:perform_async_in_queue).with(
          "bulk_republishing",
          publication.document_id,
          true,
        )

        task.invoke
      end
    end
  end

  describe "#unpublish_with_redirect" do
    describe "#for_content_id" do
    end
  end
end
