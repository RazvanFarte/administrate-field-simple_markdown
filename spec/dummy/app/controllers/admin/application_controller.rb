# frozen_string_literal: true

module Admin
  class ApplicationController < Administrate::ApplicationController
    # No authentication: this application only ever runs in specs and
    # benchmarks, bound to localhost.
  end
end
