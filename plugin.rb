# frozen_string_literal: true

# name: discourse-move-inactive-topics
# about: TODO
# meta_topic_id: TODO
# version: 0.0.1
# authors: Discourse
# url: TODO
# required_version: 2.7.0

enabled_site_setting :discourse_move_inactive_topics_enabled

module ::DiscourseMoveInactiveTopics
  PLUGIN_NAME = "discourse-move-inactive-topics"
end

require_relative "lib/discourse_move_inactive_topics/engine"

after_initialize do
  # Code which should run after Rails has finished booting
end
