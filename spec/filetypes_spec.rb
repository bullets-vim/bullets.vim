# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'filetypes' do
  it 'creates mapping for bullets on empty buffer if configured' do
    vim.command 'new'
    vim.insert '# Hello there'
    vim.feedkeys '\<cr>'
    vim.type '- this is the first bullet'
    vim.feedkeys '\<cr>'
    vim.type 'this is the second bullet'

    buffer_content = vim.echo("join(getbufline(bufname(''), 1, '$'), '\n')")

    expect(buffer_content).to eq normalize_string_indent(<<-TEXT)
      # Hello there
      - this is the first bullet
      - this is the second bullet
    TEXT
  end

  it 'should have text filetype for .txt' do
    # bullets.vim is triggered by particular filetypes;
    # if somehow your vim is recognising .txt and setting
    # filetype to something that isn't text or markdown,
    # the rest of the tests are gonna fail.
    filename = "#{SecureRandom.hex(6)}.txt"
    write_file(filename, '')

    vim.edit filename
    vim.type 'i'
    vim.feedkeys '\\<c-r>'
    vim.type '=&filetype'
    vim.feedkeys '\\<cr>'
    vim.write

    file_contents = normalize_string_indent(IO.read(filename)).strip

    expect(%w[markdown text]).to include(file_contents)
  end
end
