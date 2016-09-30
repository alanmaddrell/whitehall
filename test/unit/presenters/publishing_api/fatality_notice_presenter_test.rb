require 'test_helper'

class PublishingApi::FatalityNoticePresenterTest < ActiveSupport::TestCase
  setup do
    @fatality_notice = create(
      :fatality_notice,
      title: "Fatality Notice title",
      summary: "Fatality Notice summary",
      first_published_at: Time.zone.now
    )

    @presented_fatality_notice = PublishingApi::FatalityNoticePresenter.new(@fatality_notice)
    @presented_content = I18n.with_locale("de") { @presented_fatality_notice.content }
  end

  test "it presents a valid fatality_notice content item" do
    assert_valid_against_schema @presented_content, "fatality_notice"
  end

  test "it delegates the content id" do
    assert_equal @fatality_notice.content_id, @presented_fatality_notice.content_id
  end

  test "it presents the title" do
    assert_equal "Fatality Notice title", @presented_content[:title]
  end

  test "it presents the summary as the description" do
    assert_equal "Fatality Notice summary", @presented_content[:description]
  end

  test "it presents the base_path" do
    assert_equal "/government/fatalities/fatality-notice-title", @presented_content[:base_path]
  end

  test "it presents updated_at if public_timestamp is nil" do
    assert_equal @fatality_notice.updated_at, @presented_content[:public_updated_at]
  end

  test "it presents the publishing_app as whitehall" do
    assert_equal 'whitehall', @presented_content[:publishing_app]
  end

  test "it presents the rendering_app as government-frontend" do
    assert_equal 'government-frontend', @presented_content[:rendering_app]
  end

  test "it presents the schema_name as fatality_notice" do
    assert_equal "fatality_notice", @presented_content[:schema_name]
  end

  test "it presents the document type as fatality_notice" do
    assert_equal "fatality_notice", @presented_content[:document_type]
  end

  test "it presents the global process wide locale as the locale of the fatality_notice" do
    assert_equal "de", @presented_content[:locale]
  end
end

class PublishingApi::FatalityNoticePresenterWithPublicTimestampTest < ActiveSupport::TestCase
  setup do
    @expected_time = Time.zone.parse("10/01/2016")
    @fatality_notice = create(
      :fatality_notice
    )
    @fatality_notice.public_timestamp = @expected_time
    @presented_fatality_notice = PublishingApi::FatalityNoticePresenter.new(@fatality_notice)
  end

  test "it presents public_timestamp if it exists" do
    assert_equal @expected_time, @presented_fatality_notice.content[:public_updated_at]
  end
end

class PublishingApi::DraftFatalityNoticePresenter < ActiveSupport::TestCase
  test "it presents the Fatality Notice's parent document created_at as first_public_at" do
    presented_notice = PublishingApi::FatalityNoticePresenter.new(
      create(:draft_fatality_notice) do |fatality_notice|
        fatality_notice.document.stubs(:created_at).returns(Date.new(2015, 4, 10))
      end
    )

    assert_equal(
      Date.new(2015, 4, 10),
      presented_notice.content[:details][:first_public_at]
    )
  end
end

class PublishingApi::DraftFatalityBelongingToPublishedDocumentNoticePresenter < ActiveSupport::TestCase
  test "it presents the Fatality Notice's first_public_at" do
    presented_notice = PublishingApi::FatalityNoticePresenter.new(
      create(:published_fatality_notice) do |fatality_notice|
        fatality_notice.stubs(:first_public_at).returns(Date.new(2015, 4, 10))
      end
    )

    assert_equal(
      Date.new(2015, 04, 10),
      presented_notice.content[:details][:first_public_at]
    )
  end
end


class PublishingApi::FatalityNoticePresenterDetailsTest < ActiveSupport::TestCase
  setup do
    @fatality_notice = create(
      :fatality_notice,
      body: "*Test string*"
    )

    @presented_details = PublishingApi::FatalityNoticePresenter.new(@fatality_notice).content[:details]
  end

  test "it presents the Govspeak body as details rendered as HTML" do
    assert_equal(
      "<div class=\"govspeak\"><p><em>Test string</em></p>\n</div>",
      @presented_details[:body]
    )
  end

  test "it presents first_public_at as nil for draft" do
    assert_nil @presented_details[:first_published_at]
  end
end

class PublishingApi::PublishedFatalityNoticePresenterDetailsTest < ActiveSupport::TestCase
  setup do
    @expected_time = Time.new(2015, 12, 25)
    @fatality_notice = create(
      :fatality_notice,
      :published,
      body: "*Test string*",
      first_published_at: @expected_time
    )

    @presented_details = PublishingApi::FatalityNoticePresenter.new(@fatality_notice).content[:details]
  end

  test "it presents first_public_at as details, first_public_at" do
    assert_equal @expected_time, @presented_details[:first_public_at]
  end

  test "it presents change_history" do
    change_history = [
      {
        "public_timestamp" => @expected_time,
        "note" => "change-note"
      }
    ]

    assert_equal change_history, @presented_details[:change_history]
  end

  test "it presents the lead organisation content_ids as details, emphasised_organisations" do
    assert_equal(
      @fatality_notice.lead_organisations.map(&:content_id),
      @presented_details[:emphasised_organisations]
    )
  end
end

class PublishingApi::PublishedFatalityNoticePresenterLinksTest < ActiveSupport::TestCase
  setup do
    @fatality_notice = create(:fatality_notice)
    presented_fatality_notice = PublishingApi::FatalityNoticePresenter.new(@fatality_notice)
    @presented_links = presented_fatality_notice.links
  end

  test "it presents the organisation content_ids as links, organisations" do
    assert_equal(
      @fatality_notice.organisations.map(&:content_id),
      @presented_links[:organisations]
    )
  end

  test "it presents the topics content_ids as links, policy_areas" do
    assert_equal(
      @fatality_notice.topics.map(&:content_id),
      @presented_links[:policy_areas]
    )
  end

  test "it presents the field of operation as links, field_of_operation" do
    assert_equal(
      [@fatality_notice.operational_field.content_id],
      @presented_links[:field_of_operation]
    )
  end
end

class PublishingApi::FatalityNoticePresenterUpdateTypeTest < ActiveSupport::TestCase
  setup do
    @presented_fatality_notice = PublishingApi::FatalityNoticePresenter.new(
      create(:fatality_notice, minor_change: false)
    )
  end

  test "if the update type is not supplied it presents based on the item" do
    assert_equal "major", @presented_fatality_notice.update_type
  end
end

class PublishingApi::FatalityNoticePresenterMinorUpdateTypeTest < ActiveSupport::TestCase
  setup do
    @presented_fatality_notice = PublishingApi::FatalityNoticePresenter.new(
      create(:fatality_notice, minor_change: true)
    )
  end

  test "if the update type is not supplied it presents based on the item" do
    assert_equal "minor", @presented_fatality_notice.update_type
  end
end

class PublishingApi::FatalityNoticePresenterUpdateTypeArgumentTest < ActiveSupport::TestCase
  setup do
    @presented_fatality_notice = PublishingApi::FatalityNoticePresenter.new(
      create(:fatality_notice, minor_change: true),
      update_type: "major"
    )
  end

  test "presents based on the supplied update type argument" do
    assert_equal "major", @presented_fatality_notice.update_type
  end
end
