# frozen_string_literal: true

require_relative "../../repositories/article_repository"

module Articles
  module Services
    class Update
      def initialize(repository = ArticleRepository.new)
        @repository = repository
      end

      def call(id, params)
        article = @repository.update(id.to_i, params)
        return { ok: false, errors: ["article not found"] } unless article

        { ok: true, article: article }
      end
    end
  end
end