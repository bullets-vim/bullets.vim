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
end
