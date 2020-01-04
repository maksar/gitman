# frozen_string_literal: true

require_relative "../../../dialogs/default"

module Dialogs
  class Broken < Default
    private

    def answer(answer, params = {})
      request(answer, params)
      throw StandardError
    end
  end
end
