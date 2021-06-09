module PublishingApi
  class WorldLocationNewsPagePresenter
    attr_accessor :world_location, :update_type

    def initialize(world_location, update_type: nil)
      self.world_location = world_location
      self.update_type = update_type || "major"
    end

    def content
      content = BaseItemPresenter.new(
        world_location,
        title: title,
        update_type: update_type,
      ).base_attributes

      content.merge!(
        description: description,
        details: {},
        document_type: "placeholder_world_location_news_page",
        public_updated_at: world_location.updated_at,
        rendering_app: Whitehall::RenderingApp::WHITEHALL_FRONTEND,
        schema_name: "placeholder",
        base_path: path_for_news_page,
      )
      content.merge!(PayloadBuilder::Routes.for(path_for_news_page))
      content.merge!(PayloadBuilder::AnalyticsIdentifier.for(world_location))
    end

    def links
      {}
    end

    def content_for_rummager(content_id)
      I18n.with_locale(:en) do
        {
          content_id: content_id,
          link: path_for_news_page,
          format: "world_location_news_page", # Used for the rummager document type
          title: title,
          description: description,
          indexable_content: description,
        }
      end
    end

  private

    def path_for_news_page
      Whitehall.url_maker.world_location_news_index_path(world_location)
    end

    def description
      "#{I18n.t('world_news.uk_updates_in_country')} #{world_location.name}"
    end

    def title
      world_location.title
    end
  end
end
