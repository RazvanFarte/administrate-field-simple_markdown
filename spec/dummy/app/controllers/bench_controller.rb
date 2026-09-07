# frozen_string_literal: true

# Stable URL for the browser benchmark, which needs the edit page of the
# article that has a full-length document in every field.
class BenchController < ActionController::Base
  def edit
    redirect_to "/admin/articles/#{Article.find_by!(title: 'Benchmark article').id}/edit"
  end
end
