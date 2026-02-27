# frozen_string_literal: true

require_relative "../../repositories/article_repository"

module Articles
  module Services
    class Create
      def initialize(repository = ArticleRepository.new)
        @repository = repository
      end

      def call(params)
        title = params["title"].to_s.strip
        return failure("title is required") if title.empty?

        article = @repository.create("title" => title, "content" => params["content"])
        success(article)
      end

      private

      def success(article)
        { ok: true, article: article }
      end

      def failure(message)
        { ok: false, errors: [message] }
      end
    end
  end
end