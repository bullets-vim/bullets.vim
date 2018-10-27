# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'wrapped bullets' do
  it 'inserts a new bullet after a wrapped bullet' do
    test_bullet_inserted('do that', <<-INIT, <<-EXPECTED)
      # Hello there
      - do this
        this is the second line of the first bullet
    INIT
      # Hello there
      - do this
        this is the second line of the first bullet
      - do that
    EXPECTED
  end

  it 'does not insert wrapped bullets unnecessarily' do
    test_bullet_inserted('do that', <<-INIT, <<-EXPECTED)
      # Hello there
      - do this
        this is the second line of the first bullet

      no bullets after this line
    INIT
      # Hello there
      - do this
        this is the second line of the first bullet

      no bullets after this line
      do that
    EXPECTED
  end
end
