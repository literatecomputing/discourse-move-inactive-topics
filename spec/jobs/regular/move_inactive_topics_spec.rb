# frozen_string_literal: true
#

RSpec.describe Jobs::MoveInactiveTopics do
  fab!(:user)
  fab!(:category) do
    Fabricate(:category_with_definition, user: user, description: "this is a great category")
  end
  fab!(:exempt_category) do
    Fabricate(:category_with_definition, user: user, description: "this is an exempt category")
  end
  fab!(:topic) { Fabricate(:topic, category: category) }
  fab!(:exempt_topic) { Fabricate(:topic, category: exempt_category) }
  fab!(:post) { Fabricate(:post, topic: topic) }
  fab!(:epost) { Fabricate(:post, topic: exempt_topic) }
  fab!(:skip_archive_tag) { Fabricate(:tag, name: "skip-archive") }
  fab!(:tagged_topic) { create_topic(created_at: 1.minute.ago, tags: [skip_archive_tag.name]) }
  fab!(:description_topic) { create_topic(created_at: 1.minute.ago, category: category) }
  fab!(:archive_category) { Fabricate(:category, name: "Archive") }

  before do
    SiteSetting.move_inactive_topics_enabled = true
    SiteSetting.move_inactive_topics_archive_category = archive_category.id
    SiteSetting.move_inactive_topics_archive_after_days = 180
    SiteSetting.move_inactive_topics_tag_to_skip_archiving = skip_archive_tag.name
    SiteSetting.move_inactive_topics_skip_categories = "1|2|#{exempt_category.id}"
  end

  context "in a category with a topic" do
    it "should move an inactive topic to the right category" do
      category.update_column(:topic_id, description_topic.id)
      expect(topic.category.id).not_to eq(archive_category.id)
      freeze_time 181.days.from_now do
        Jobs::MoveInactiveTopics.new.execute({})
        topic.reload
        expect(topic.category.id).to eq(archive_category.id)
      end
    end

    it "should not move category descriptions" do
      category.update_column(:topic_id, description_topic.id)
      expect(category.topic_id.to_i).to eq(description_topic.id)
      t = Topic.find(category.topic_id)
      freeze_time 181.days.from_now do
        Jobs::MoveInactiveTopics.new.execute({})
        expect(t.category_id).to eq(category.id)
      end
    end

    it "should not move old topic with the tag_to_skip_archiving tag" do
      category.update_column(:topic_id, description_topic.id)
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
      category.update_column(:topic_id, description_topic.id)
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
