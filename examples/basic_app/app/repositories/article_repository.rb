# frozen_string_literal: true

require_relative "../entities/article"
require_relative "../../config/db"

class ArticleRepository
  def initialize(dataset = DB[:articles])
    @dataset = dataset
  end

  def create(attrs)
    now = Time.now
    id = @dataset.insert(
      title: attrs.fetch("title"),
      content: attrs["content"],
      created_at: now,
      updated_at: now
    )

    row = @dataset.where(id: id).first
    Article.new(row)
  end

  def update(id, attrs)
    changes = {}
    changes[:title] = attrs["title"] if attrs.key?("title")
    changes[:content] = attrs["content"] if attrs.key?("content")
    changes[:updated_at] = Time.now

    @dataset.where(id: id).update(changes)
    row = @dataset.where(id: id).first
    row && Article.new(row)
  end

  def destroy(id)
    @dataset.where(id: id).delete.positive?
  end
end