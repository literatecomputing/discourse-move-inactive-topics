# frozen_string_literal: true

RSpec.describe Jobs::MoveInactiveTopics do
  fab!(:user)
  fab!(:category)
  fab!(:description_topic) { Fabricate(:topic, category: category) }
  fab!(:description_post) { create_post(topic: description_topic) }
  fab!(:exempt_category) { Fabricate(:category) }
  fab!(:skip_archive_tag) { Fabricate(:tag, name: "skip-archive") }
  fab!(:archive_category) { Fabricate(:category, user: user) }
  fab!(:topic) { Fabricate(:topic, category: category) }
  fab!(:topic_post) { Fabricate(:post, topic: topic) }
  fab!(:exempt_topic) { Fabricate(:topic, category: exempt_category) }
  fab!(:exempt_topic_post) { Fabricate(:post, topic: exempt_topic) }
  fab!(:tagged_topic) { Fabricate(:topic, category: category) }
  fab!(:tagged_topic_post) { Fabricate(:post, topic: tagged_topic) }

  before do
    category.topic_id = description_topic.id
    setup_site_settings
  end

  def setup_site_settings
    SiteSetting.normalize_emails = true
    SiteSetting.move_inactive_topics_enabled = true
    SiteSetting.move_inactive_topics_archive_category = archive_category.id
    SiteSetting.move_inactive_topics_archive_after_days = 180
    SiteSetting.move_inactive_topics_tag_to_skip_archiving = skip_archive_tag.name
    SiteSetting.move_inactive_topics_skip_categories = "#{exempt_category.id}"
  end

  context "in a category with a topic" do
    it "should move an inactive topic to the archive category" do
      puts "using topic: #{topic.inspect}"
      expect(topic.category.id).not_to eq(archive_category.id)
      freeze_time 181.days.from_now do
        Jobs::MoveInactiveTopics.new.execute({})
        topic.reload
        expect(topic.category.id).to eq(archive_category.id)
      end
    end

    # Additional tests...
    it "should not move category descriptions" do
      expect(category.topic_id.to_i).to eq(description_topic.id)
      t = Topic.find(category.topic_id)
      freeze_time 181.days.from_now do
        Jobs::MoveInactiveTopics.new.execute({})
        expect(t.category_id).to eq(category.id)
      end
    end

    it "should not move old topic with the tag_to_skip_archiving tag" do
      expect(tagged_topic.category_id).not_to eq(archive_category.id)
      freeze_time 6.months.from_now do
        Jobs::MoveInactiveTopics.new.execute({})
        expect(tagged_topic.category_id).not_to eq(archive_category.id)
      end
    end

    # it "should not move PM" do
    #   expect(category_id).to eq(topic.id)
    # end

    it "should not move topic in exempt category" do
      expect(exempt_topic.category).not_to eq(archive_category)
      freeze_time 181.days.from_now do
        Jobs::MoveInactiveTopics.new.execute({})
        expect(exempt_topic.category).not_to eq(archive_category)
      end
    end

    it "should not move topic newer than num_months_to_archive" do
      freeze_time 5.months.from_now do
        Jobs::MoveInactiveTopics.new.execute({})
        expect(topic.category).not_to eq(archive_category)
      end
    end
  end
end
