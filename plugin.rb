# frozen_string_literal: true

# name: discourse-move-inactive-topics
# about: move inactive topics to a different category
# version: 0.0.1
# authors: pfaffman
# url: TODO
# required_version: 2.7.0

enabled_site_setting :move_inactive_topics_enabled

module ::DiscourseMoveInactiveTopics
  PLUGIN_NAME = "discourse-move-inactive-topics"
end

after_initialize do
  require_relative "jobs/scheduled/move_inactive_topics.rb"
  require_relative "lib/discourse_move_inactive_topics/engine"

  # Code which should run after Rails has finished booting
end
