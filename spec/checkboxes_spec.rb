# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'checkboxes' do
  it 'inserts another checkbox after the previous one' do
    test_bullet_inserted('do that', <<-INIT, <<-EXPECTED)
      # Hello there
      - [ ] do this
    INIT
      # Hello there
      - [ ] do this
      - [ ] do that
    EXPECTED
  end

  it 'inserts an empty checkbox even if prev line was checked' do
    test_bullet_inserted('do that', <<-INIT, <<-EXPECTED)
      # Hello there
      - [x] do this
    INIT
      # Hello there
      - [x] do this
      - [ ] do that
    EXPECTED
  end
end
