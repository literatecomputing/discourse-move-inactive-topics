# frozen_string_literal: true

DiscourseMoveInactiveTopics::Engine.routes.draw do
  get "/examples" => "examples#index"
  # define routes here
end

Discourse::Application.routes.draw { mount ::DiscourseMoveInactiveTopics::Engine, at: "discourse-move-inactive-topics" }
