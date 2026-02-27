# frozen_string_literal: true

class Article
  attr_reader :id, :title, :content, :created_at, :updated_at

  def initialize(attrs = {})
    @id = attrs[:id] || attrs["id"]
    @title = attrs[:title] || attrs["title"]
    @content = attrs[:content] || attrs["content"]
    @created_at = attrs[:created_at] || attrs["created_at"]
    @updated_at = attrs[:updated_at] || attrs["updated_at"]
  end

  def to_h
    {
      id: id,
      title: title,
      content: content,
      created_at: created_at,
      updated_at: updated_at
    }
  end
end