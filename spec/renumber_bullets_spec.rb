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
      1. this is the first bullet
      2. this is the second bullet
      3. this is the third bullet
      4. this is the fourth bullet\n
    TEXT
  end

  it 'renumbers a list containing checkboxes' do
    filename = "#{SecureRandom.hex(6)}.txt"
    write_file(filename, <<-TEXT)
      # Hello there
      33. this is the first bullet
      - [x] this is the second bullet
      1.     this is the third bullet
        - [ ] this is the fourth bullet
      4. this is the fifth bullet

      - [o] second bullet list
      b. second item
      - [x] third item
    TEXT

    vim.edit filename
    vim.type 'j'
    vim.feedkeys 'gN'
    vim.type '}j'
    vim.feedkeys 'gN'
    vim.write

    file_contents = IO.read(filename)

    expect(file_contents).to eq normalize_string_indent(<<-TEXT)
      # Hello there
      1. this is the first bullet
      - [x] this is the second bullet
      2. this is the third bullet
        - [ ] this is the fourth bullet
      3. this is the fifth bullet

      - [o] second bullet list
      a. second item
      - [x] third item\n
    TEXT
  end

  it 'renumbers a nested list' do
    filename = "#{SecureRandom.hex(6)}.txt"
    write_file(filename, <<-TEXT)
      # Hello there
      0. zero bullet

      X. first bullet

      - second bullet
      \twrapped line

      a. third bullet

      I. fourth bullet

      \tV. fifth bullet

      \t\tB. sixth bullet

      \t* seventh bullet

      \t\ti. eighth bullet

      \t\tx. ninth bullet
      \t\t\t wrapped line

      \t\t\ta. tenth bullet
      wrapped line without indent

      \tC. eleventh bullet
      \t\t0. twelfth bullet

      \t\t\t* thirteenth bullet

      \t\t\t\t+ fourteenth bullet

      \t\t\tb. fifteenth bullet

      \t\ta. sixteenth bullet

      \t\t\t8. seventeenth bullet

      \t\t\t0. eighteenth bullet
      \t\t\t\t wrapped line

      \tnormal indented line
      next normal line

      1. nineteenth bullet

      x. twentieth bullet


      v. twenty-first bullet
      - twenty-second bullet


      v. twenty-third bullet
    TEXT

    vim.edit filename
    vim.command 'let g:bullets_line_spacing=2'
    vim.normal '3j'
    vim.feedkeys 'gN'
    vim.normal 'G3k'
    vim.feedkeys 'gN'
    vim.write

    file_contents = IO.read(filename)

    expect(file_contents).to eq normalize_string_indent(<<-TEXT)
      # Hello there
      1. zero bullet

      2. first bullet

      - second bullet
      \twrapped line

      3. third bullet

      4. fourth bullet

      \tI. fifth bullet

      \t\tA. sixth bullet

      \t* seventh bullet

      \t\ti. eighth bullet

      \t\tii. ninth bullet
      \t\t\t wrapped line

      \t\t\ta. tenth bullet
      wrapped line without indent

      \tII. eleventh bullet
      \t\t1. twelfth bullet

      \t\t\t* thirteenth bullet

      \t\t\t\t+ fourteenth bullet

      \t\t\ta. fifteenth bullet

      \t\t2. sixteenth bullet

      \t\t\t1. seventeenth bullet

      \t\t\t2. eighteenth bullet
      \t\t\t\t wrapped line

      \tnormal indented line
      next normal line

      1. nineteenth bullet

      x. twentieth bullet


      i. twenty-first bullet
      - twenty-second bullet


      v. twenty-third bullet

    TEXT
  end

  it 'visually renumbers a nested list' do
    filename = "#{SecureRandom.hex(6)}.txt"
    write_file(filename, <<-TEXT)
      # Hello there
      0. zero bullet

      X. first bullet

      - second bullet
      \twrapped line

      a. third bullet

      I. fourth bullet

      \tV. fifth bullet

      \t\tB. sixth bullet

      \t* seventh bullet

      \t\ti. eighth bullet

      \t\tx. ninth bullet
      \t\t\t wrapped line

      \t\t\ta. tenth bullet
      wrapped line without indent

      \tC. eleventh bullet
      \t\t0. twelfth bullet

      \t\t\t* thirteenth bullet

      \t\t\t\t+ fourteenth bullet

      \t\t\td. fifteenth bullet

      \t\ta. sixteenth bullet

      \t\t\t8. seventeenth bullet

      \t\t\t0. eighteenth bullet
      \t\t\t\t wrapped line

      \tnormal indented line
      next normal line

      1. nineteenth bullet

      x. twentieth bullet


      v. twenty-first bullet
      - twenty-second bullet


      v. twenty-third bullet
    TEXT

    vim.edit filename
    vim.command 'let g:bullets_line_spacing=2'
    vim.type '2jVGk'
    vim.feedkeys 'gN'
    vim.write

    file_contents = IO.read(filename)

    expect(file_contents).to eq normalize_string_indent(<<-TEXT)
      # Hello there
      0. zero bullet

      I. first bullet

      - second bullet
      \twrapped line

      II. third bullet

      III. fourth bullet

      \tI. fifth bullet

      \t\tA. sixth bullet

      \t* seventh bullet

      \t\ti. eighth bullet

      \t\tii. ninth bullet
      \t\t\t wrapped line

      \t\t\ta. tenth bullet
      wrapped line without indent

      \tII. eleventh bullet
      \t\t1. twelfth bullet

      \t\t\t* thirteenth bullet

      \t\t\t\t+ fourteenth bullet

      \t\t\ti. fifteenth bullet

      \t\t2. sixteenth bullet

      \t\t\t1. seventeenth bullet

      \t\t\t2. eighteenth bullet
      \t\t\t\t wrapped line

      \tnormal indented line
      next normal line

      IV.  nineteenth bullet

      V.   twentieth bullet


      VI.  twenty-first bullet
      - twenty-second bullet


      v. twenty-third bullet

    TEXT
  end
end
