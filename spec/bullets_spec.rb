require 'spec_helper'

RSpec.describe 'Bullets.vim' do
  context 'inserting new bullets' do
    context 'on return key when cursor is at EOL' do
      it 'adds a new bullet if the previous line had a known bullet type' do
        write_file('test.md', <<-EOF)
          # Hello there
          - this is the first bullet
        EOF

        vim.edit 'test.md'
        vim.type 'GA'
        vim.feedkeys '\<cr>'
        vim.type 'second bullet'
        vim.write

        file_contents = IO.read('test.md')

        expect(file_contents).to eq normalize_string_indent(<<-EOF)
          # Hello there
          - this is the first bullet
          - second bullet\n
        EOF
      end
    end

    context 'on return key when cursor is not at EOL' do
      it 'splits the line and does not add a bullet' do
        write_file('test.md', <<-EOF)
          # Hello there
          - this is the first bullet
        EOF

        vim.edit 'test.md'
        vim.type 'G$i'
        vim.feedkeys '\<cr>'
        vim.type 'second bullet'
        vim.write

        file_contents = IO.read('test.md')

        expect(file_contents).to eq normalize_string_indent(<<-EOF)
          # Hello there
          - this is the first bulle
          second bullett\n
        EOF
      end
    end
  end
end
