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

  it 'renumbers a nested list correctly' do
    filename = "#{SecureRandom.hex(6)}.txt"
    write_file(filename, <<-TEXT)
      # Hello there
      X. first bullet
      V. second bullet
      3. third bullet
      I. fourth bullet
      V. fifth bullet
      \tB. sixth bullet
      \tB. seventh bullet
      \t\ti. eighth bullet
      \t\tx. ninth bullet
      \t\ta. tenth bullet
      \tC. eleventh bullet
      \t\t1. twelfth bullet
      \t\t1. thirteenth bullet
      \t\t1. fourteenth bullet
      \td. fifteenth bullet
      \t\ta. sixteenth bullet
      \t\t\t8. seventeenth bullet
      \t\t\t0. eighteenth bullet
      \t\t\t\tv. nineteenth bullet
      \t\t\t\ti. twentieth bullet
      \t\t\t\ti. twenty-first bullet
      \t\t\tc. twenty-second bullet
      \t\t\t\tX. twenty-third bullet
      \t\t\t\t\t- twenty-fourth bullet
      \t\t\t\t\t- twenty-fifth bullet
      \tII. twenty-sixth bullet
      \t\t- twenty-seventh bullet
      0. twenty-eighth bullet
    TEXT

    vim.edit filename
    vim.type 'ggVG'
    vim.feedkeys 'gN'
    vim.write

    file_contents = IO.read(filename)

    expect(file_contents).to eq normalize_string_indent(<<-TEXT)
      # Hello there
      I. first bullet
      II. second bullet
      III. third bullet
      IV.  fourth bullet
      V.   fifth bullet
      \tA. sixth bullet
      \tB. seventh bullet
      \t\ti. eighth bullet
      \t\tii. ninth bullet
      \t\tiii. tenth bullet
      \tC. eleventh bullet
      \t\t1. twelfth bullet
      \t\t2. thirteenth bullet
      \t\t3. fourteenth bullet
      \tD. fifteenth bullet
      \t\ta. sixteenth bullet
      \t\t\t1. seventeenth bullet
      \t\t\t2. eighteenth bullet
      \t\t\t\ti. nineteenth bullet
      \t\t\t\tii. twentieth bullet
      \t\t\t\tiii. twenty-first bullet
      \t\t\t3. twenty-second bullet
      \t\t\t\tI. twenty-third bullet
      \t\t\t\t\t- twenty-fourth bullet
      \t\t\t\t\t- twenty-fifth bullet
      \tE. twenty-sixth bullet
      \t\t- twenty-seventh bullet
      VI.  twenty-eighth bullet

    TEXT
  end
end
