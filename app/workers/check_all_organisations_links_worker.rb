# Enqueues CheckAllEditionsLinksWorker for all organisations
require "sidekiq-scheduler"

class CheckAllOrganisationsLinksWorker
  include Sidekiq::Worker

  def perform
    GovukStatsd.time('link-checking-debug.check-all-organisations-worker') do
      Rails.logger.info("[link-checking-debug][job_#{self.jid}]: Queuing #{organisations.count} jobs to check organisations")
      organisations.each do |organisation|
        CheckOrganisationLinksWorker.perform_async(organisation.id)
      end
      Rails.logger.info("[link-checking-debug][job_#{self.jid}]: Done queuing #{organisations.count} jobs to check organisations")
    end
  end

private

  def organisations
    Organisation.all
  end
end
