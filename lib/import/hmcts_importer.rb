module Import
  class HmctsImporter
    PUBLICATION_TYPE_SLUGS = {
      "Form" => "forms",
      "Guidance" => "guidance",
    }.freeze

    def initialize(dry_run)
      @dry_run = dry_run
    end

    def import(csv_path)
      importer_user = User.find_by(name: "Automatic Data Importer")
      raise "Could not find 'Automatic Data Importer' user" unless importer_user

      HmctsCsvParser.publications(csv_path).each do |publication_data|
        # puts publication_data

        begin
          publication = Publication.new
          publication.publication_type = PublicationType.find_by_slug(publication_type_slug(publication_data[:publication_type]))
          publication.title = publication_data[:title]
          publication.summary = publication_data[:summary]
          publication.body = publication_data[:body]
          publication.topics = publication_data[:policy_areas].map { |policy_area| Topic.find_by!(name: policy_area) }
          # TODO: Use the org from the CSV. This currently doesn't work because the org in the CSV doesn't
          # match the Whitehall org name exactly.
          publication.lead_organisations = [default_organisation]
          # publication.lead_organisations = publication_data[:lead_organisations].map { |org| Organisation.find_by(name: org) }
          publication.supporting_organisations = publication_data[:supporting_organisations].map { |org| Organisation.find_by(name: org) }
          publication.creator = importer_user
          # TODO: Confirm the alternative format provider org and email address with HMCTS
          publication.alternative_format_provider = default_organisation
          publication.first_published_at = Date.parse(publication_data[:previous_publishing_date])
          publication.access_limited = publication_data[:access_limited]

          publication_data[:excluded_nations].each do |excluded_nation|
            nation = Nation.find_by_name!(excluded_nation)
            exclusion = NationInapplicability.new(nation: nation)
            publication.nation_inapplicabilities << exclusion
          end

          publication.validate!
          publication.save! unless dry_run?
          # puts "Created publication with ID #{publication.id}"

          publication_data[:attachments].each do |attachment|
            create_attachment(attachment, publication)
          end
        rescue StandardError => error
          # TODO: Fix row output: error may be from subsequent row because it's from a translated version
          puts "Error for form #{publication_data[:page_id]} in row #{publication_data[:csv_row]}"
          puts error
        end
      end
    end

    def default_organisation
      @_default_organisation ||= Organisation.find_by(name: "HM Courts & Tribunals Service")
    end

    def publication_type_slug(name)
      PUBLICATION_TYPE_SLUGS[name] || raise("Unknown publication type '#{name}'")
    end

    def create_attachment(attachment, publication)
      temp_file_path = "#{temp_directory}/#{attachment[:file_name]}"

      if dry_run?
        File.open(temp_file_path, "w") { |file| file.write("Placeholder content") }
      else
        download_attachment(attachment[:url], temp_file_path)
      end

      attachment_data = AttachmentData.new(file: File.new(temp_file_path))
      file_attachment = FileAttachment.new(
        title: attachment[:title],
        attachment_data: attachment_data,
        attachable: publication,
      )
      file_attachment.validate!
      file_attachment.save! unless dry_run?

      # puts "Added attachment #{temp_file_path}"
    end

    def download_attachment(hmcts_url, file_path)
      url = hmcts_url.sub(/^http\:/, "https:")
      response = Faraday.get(url)

      File.open(file_path, "wb") do |file|
        file.write(response.body)
      end
    end

    def temp_directory
      @_temp_directory ||= Dir.mktmpdir
    end

    def dry_run?
      @dry_run
    end
  end
end
