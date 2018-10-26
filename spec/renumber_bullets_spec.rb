# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 're-numbering' do
  it 'renumbers a selected list correctly' do
    filename = "#{SecureRandom.hex(6)}.txt"
    write_file(filename, <<-TEXT)
      # Hello there
      33. this is the first bullet
      2. this is the second bullet
      1.     this is the third bullet
      4. this is the fourth bullet
    TEXT

    vim.edit filename
    vim.type 'ggVG'
    vim.feedkeys 'gN'
    vim.write

    file_contents = IO.read(filename)

    expect(file_contents).to eq normalize_string_indent(<<-TEXT)
      # Hello there
      1.  this is the first bullet
      2.  this is the second bullet
      3.  this is the third bullet
      4.  this is the fourth bullet\n
    TEXT
  end
end
