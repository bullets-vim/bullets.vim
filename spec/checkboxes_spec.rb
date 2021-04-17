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

  it 'inserts a * checkbox after the previous one' do
    test_bullet_inserted('do that', <<-INIT, <<-EXPECTED)
      # Hello there
      * [ ] do this
    INIT
      # Hello there
      * [ ] do this
      * [ ] do that
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

  it 'toggle a bullet' do
    filename = "#{SecureRandom.hex(6)}.txt"
    write_file(filename, <<-TEXT)
      # Hello there
      - [ ] first bullet
      - [X] second bullet
      - [x] third bullet
      - [.] fourth bullet
      - [o] fifth bullet
      - [O] sixth bullet
      - not a checkbox
    TEXT

    vim.edit filename
    vim.normal 'j'
    vim.command 'ToggleCheckbox'
    vim.normal 'j'
    vim.command 'ToggleCheckbox'
    vim.normal 'j'
    vim.command 'ToggleCheckbox'
    vim.normal 'j'
    vim.command 'ToggleCheckbox'
    vim.normal 'j'
    vim.command 'ToggleCheckbox'
    vim.normal 'j'
    vim.command 'ToggleCheckbox'
    vim.normal 'j'
    vim.command 'ToggleCheckbox'
    vim.write

    file_contents = IO.read(filename)

    expect(file_contents).to eq normalize_string_indent(<<-TEXT)
      # Hello there
      - [X] first bullet
      - [ ] second bullet
      - [ ] third bullet
      - [X] fourth bullet
      - [X] fifth bullet
      - [X] sixth bullet
      - not a checkbox

    TEXT
  end

  it 'toggle a bullet and adjust parent' do
    filename = "#{SecureRandom.hex(6)}.txt"
    write_file(filename, <<-TEXT)
      # Hello there
      - [ ] first bullet
        - [ ] second bullet
          - [ ] third bullet
    TEXT

    vim.edit filename
    vim.normal 'G'
    vim.command 'ToggleCheckbox'
    vim.write

    file_contents = IO.read(filename)

    expect(file_contents).to eq normalize_string_indent(<<-TEXT)
      # Hello there
      - [X] first bullet
        - [X] second bullet
          - [X] third bullet

    TEXT
  end

  it 'toggle a bullet and adjust children' do
    filename = "#{SecureRandom.hex(6)}.txt"
    write_file(filename, <<-TEXT)
      # Hello there
      - [ ] first bullet
        - [ ] second bullet
          - [ ] third bullet
    TEXT

    vim.edit filename
    vim.normal 'j'
    vim.command 'ToggleCheckbox'
    vim.write

    file_contents = IO.read(filename)

    expect(file_contents).to eq normalize_string_indent(<<-TEXT)
      # Hello there
      - [X] first bullet
        - [X] second bullet
          - [X] third bullet

    TEXT
  end

  it 'toggle a bullet and calculate completion' do
    filename = "#{SecureRandom.hex(6)}.txt"
    write_file(filename, <<-TEXT)
      # Hello there
      - [ ] first bullet
        - [ ] second bullet
          - [ ] third bullet
          - [ ] fourth bullet
          - [ ] fifth bullet
          - [ ] sixth bullet
        - [ ] seventh bullet
          - [ ] eighth bullet
          - [ ] ninth bullet
          - [ ] tenth bullet
          - [ ] eleventh bullet
        - [ ] twelfth bullet
          - [ ] thirteenth bullet
          - [ ] fourteenth bullet
          - [ ] fifteenth bullet
          - [ ] sixteenth bullet
        - [X] seventeenth bullet
          - [X] eighteenth bullet
          - [X] ninteenth bullet
          - [X] twentieth bullet
          - [X] twenty-first bullet
    TEXT

    vim.edit filename
    vim.normal '3j'
    vim.command 'ToggleCheckbox'
    vim.normal '6j'
    vim.command 'ToggleCheckbox'
    vim.normal 'j'
    vim.command 'ToggleCheckbox'
    vim.normal 'j'
    vim.command 'ToggleCheckbox'
    vim.normal '2j'
    vim.command 'ToggleCheckbox'
    vim.normal 'j'
    vim.command 'ToggleCheckbox'
    vim.normal 'j'
    vim.command 'ToggleCheckbox'
    vim.normal 'j'
    vim.command 'ToggleCheckbox'
    vim.normal '2j'
    vim.command 'ToggleCheckbox'
    vim.write

    file_contents = IO.read(filename)

    expect(file_contents).to eq normalize_string_indent(<<-TEXT)
      # Hello there
      - [.] first bullet
        - [.] second bullet
          - [X] third bullet
          - [ ] fourth bullet
          - [ ] fifth bullet
          - [ ] sixth bullet
        - [O] seventh bullet
          - [ ] eighth bullet
          - [X] ninth bullet
          - [X] tenth bullet
          - [X] eleventh bullet
        - [X] twelfth bullet
          - [X] thirteenth bullet
          - [X] fourteenth bullet
          - [X] fifteenth bullet
          - [X] sixteenth bullet
        - [O] seventeenth bullet
          - [ ] eighteenth bullet
          - [X] ninteenth bullet
          - [X] twentieth bullet
          - [X] twenty-first bullet

    TEXT
  end

  it 'adds and toggles bullets using UTF characters' do
    filename = "#{SecureRandom.hex(6)}.txt"
    write_file(filename, <<-TEXT)
      # Hello there
      - [ ] first bullet
    TEXT

    vim.edit filename
    vim.command 'let g:bullets_checkbox_markers="✗○◐●✓"'
    vim.normal 'j'
    vim.command 'ToggleCheckbox'
    vim.feedkeys 'o'
    vim.type 'second bullet'
    vim.feedkeys '\<cr>\<C-t>'
    vim.type 'third bullet'
    vim.feedkeys '\<cr>'
    vim.type 'fourth bullet<esc>'
    vim.command 'ToggleCheckbox'
    vim.feedkeys 'o\<C-d>'
    vim.type 'fifth bullet<esc>'
    vim.command 'ToggleCheckbox'
    vim.feedkeys 'o'
    vim.type 'sixth bullet'
    vim.command 'ToggleCheckbox'
    vim.command 'ToggleCheckbox'
    vim.write

    file_contents = IO.read(filename)

    expect(file_contents).to eq normalize_string_indent(<<-TEXT)
      # Hello there
      - [✓] first bullet
      - [◐] second bullet
      \t- [✗] third bullet
      \t- [✓] fourth bullet
      - [✓] fifth bullet
      - [✗] sixth bullet

    TEXT
  end
end
