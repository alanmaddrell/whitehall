module PublishingApi
  class WorldLocationNewsArticlePresenter
    include UpdateTypeHelper
    attr_reader :item
    attr_reader :update_type

    def initialize(item, update_type: nil)
      @item = item
      @update_type = update_type || default_update_type(item)
    end

    def content_id
      item.content_id
    end

    def content
      content = BaseItemPresenter.new(item).base_attributes
      content.merge!(
        description: item.summary,
        details: details,
        document_type: "news_article",
        public_updated_at: item.public_timestamp || item.updated_at,
        rendering_app: item.rendering_app,
        schema_name: "world_location_news_article",
      )
      content.merge!(PayloadBuilder::AccessLimitation.for(item))
      content.merge!(PayloadBuilder::PublicDocumentPath.for(item))
      content.merge!(PayloadBuilder::FirstPublishedAt.for(item))
    end

    def links
      LinksPresenter.new(item).extract(
        %i(worldwide_organisations parent policy_areas topics world_locations)
      )
    end

    private

    def details
      {
        body: govspeak_renderer.govspeak_edition_to_html(item),
        change_history: item.change_history.as_json,
      }.tap do |details_hash|
        details_hash[:image] = image_details if image_available?
        details_hash.merge!(PayloadBuilder::PoliticalDetails.for(item))
        details_hash.merge!(PayloadBuilder::TagDetails.for(item))
        details_hash.merge!(PayloadBuilder::FirstPublicAt.for(item))
      end
    end

    def image_details
      {
        url: Whitehall.public_asset_host + presented_world_location_news_article.lead_image_path,
        alt_text: presented_world_location_news_article.lead_image_alt_text
      }
    end

    def image_available?
      item.images.any?
    end

    def govspeak_renderer
      @govspeak_renderer ||= Whitehall::GovspeakRenderer.new
    end

    def presented_world_location_news_article
      ::WorldLocationNewsArticlePresenter.new(item)
    end
  end
end
