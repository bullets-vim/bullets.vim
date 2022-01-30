# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'AsciiDoc' do
  it 'maintains indentation in ascii doc bullets' do
    test_bullet_inserted('rats', <<-INIT, <<-EXPECTED)
      = Pets!
      * dogs
      ** cats
    INIT
      = Pets!
      * dogs
      ** cats
      ** rats
    EXPECTED
  end

  it 'supports dot bullets' do
    test_bullet_inserted('cats', <<-INIT, <<-EXPECTED)
      = Pets!
      . dogs
    INIT
      = Pets!
      . dogs
      . cats
    EXPECTED
  end

  it 'supports nested dot bullets' do
    pending('FIXME: this test fails, but the functionality works')
    test_bullet_inserted('rats', <<-INIT, <<-EXPECTED)
      = Pets!
      . dogs
      .. cats
    INIT
      = Pets!
      . dogs
      .. cats
      .. rats
    EXPECTED
  end
end
