# frozen_string_literal: true

module Jobs
  class MoveInactiveTopics < ::Jobs::Scheduled
    every SiteSetting.move_inactive_topics_job_days.days

    def execute(args)
      puts "Starting MoveInactiveTopics at #{Time.zone.now}"
      return unless SiteSetting.move_inactive_topics_enabled
      return if SiteSetting.move_inactive_topics_archive_after_days.to_i <= 0
      return if SiteSetting.move_inactive_topics_archive_category.to_i <= 0

      puts "Getting inactive topics"

      inactive_topics =
        Topic
          .where("bumped_at < ?", SiteSetting.move_inactive_topics_archive_after_days.days.ago)
          .where(archetype: "regular")
          .where("category_id != ?", SiteSetting.move_inactive_topics_archive_category)
          .where(
            "category_id not in (?)",
            SiteSetting.move_inactive_topics_skip_categories.split("|").map(&:to_i),
          )

      puts "Got #{inactive_topics.count} inactive topics"
      return if inactive_topics.count == 0
      archive_category = Category.find(SiteSetting.move_inactive_topics_archive_category.to_i)
      revision_user = User.find_by_username(SiteSetting.move_inactive_topics_revision_user)
      inactive_topics.each do |topic|
        puts "processing #{topic.id} -- #{topic.title}"
        # skip if is category description
        if topic.id == topic.category.topic_id
          puts "Skipping this topic because it is a category description"
        end
        next if topic.id == topic.category.topic_id
        # Move the topic to a different category
        changes = {
          category_id: archive_category.id,
          edit_reason:
            I18n.t(
              "move_inactive_topics.archive_reason",
              days: SiteSetting.move_inactive_topics_archive_after_days,
            ),
        }

        opts = { bypass_bump: true, bypass_rate_limiter: true }

        puts "calling the post revisor--#{topic.title}(#{topic.id}) category: #{topic.category_id}->#{archive_category.id}. Here: #{changes.inspect}"
        PostRevisor.new(topic.first_post).revise!(revision_user, changes, opts)
      end
    end
  end
end
