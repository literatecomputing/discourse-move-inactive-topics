# **Discourse Move Inactive Topics** Plugin

**Plugin Summary**

For more information, please see: **url to meta topic**


      freeze_time 6.hours.from_now do


    it "creates expected PM" do
      freeze_time 6.hours.from_now do
        expect {
          Jobs::DiscourseAutomation::Tracker.new.execute

          raws = Post.order(created_at: :desc).limit(3).pluck(:raw)
          expect(raws.any? { |r| r.start_with?("@#{user_1.username}") }).to be_truthy
          expect(raws.any? { |r| r.start_with?("@#{user_2.username}") }).to be_truthy
          expect(raws.any? { |r| r.start_with?("@#{user_3.username}") }).to be_truthy
          expect(raws.any? { |r| r.end_with?("#{user_1.username}") }).to be_truthy
          expect(raws.any? { |r| r.end_with?("#{user_2.username}") }).to be_truthy
          expect(raws.any? { |r| r.end_with?("#{user_3.username}") }).to be_truthy

          title = Post.order(created_at: :desc).limit(3).map { |post| post.topic.title }.uniq.first
          expect(title).to eq("Gift #{Time.zone.now.year}")
        }.to change { Post.count }.by(3) # each pair receives a PM
      end
    end
  end


    it "works" do
      expect(topic.pinned_at).to be_nil

      automation.trigger!

      # expect_enqueued_with is sometimes failing with float precision
      job = Jobs::UnpinTopic.jobs.last
      expect(job["args"][0]["topic_id"]).to eq(topic.id)
      expect(Time.at(job["at"])).to be_within_one_minute_of(10.days.from_now)

      topic.reload

      expect(topic.pinned_at).to be_within_one_minute_of(Time.zone.now)
      expect(topic.pinned_globally).to be_falsey
      expect(topic.pinned_until).to be_within_one_minute_of(10.days.from_now)
    end
  end
