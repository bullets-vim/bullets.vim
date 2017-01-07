require 'spec_helper'

RSpec.describe 'Bullets.vim' do
  describe 'inserting new bullets' do
    context 'on return key when cursor is at EOL' do
      it 'adds a new bullet if the previous line had a known bullet type' do
        filename = "#{SecureRandom.hex(6)}.md"
        write_file(filename, <<-EOF)
          # Hello there
          - this is the first bullet
        EOF

        vim.edit filename
        vim.type 'GA'
        vim.feedkeys '\<cr>'
        vim.type 'second bullet'
        vim.write

        file_contents = IO.read(filename)

        expect(file_contents).to eq normalize_string_indent(<<-EOF)
          # Hello there
          - this is the first bullet
          - second bullet\n
        EOF
      end
    end

    context 'on return key when cursor is not at EOL' do
      it 'splits the line and does not add a bullet' do
        filename = "#{SecureRandom.hex(6)}.md"
        write_file(filename, <<-EOF)
          # Hello there
          - this is the first bullet
        EOF

        vim.edit filename
        vim.type 'G$i'
        vim.feedkeys '\<cr>'
        vim.type 'second bullet'
        vim.write

        file_contents = IO.read(filename)

        expect(file_contents).to eq normalize_string_indent(<<-EOF)
          # Hello there
          - this is the first bulle
          second bullett\n
        EOF
      end
    end
  end

  describe 're-numbering' do
    it 'renumbers a selected list correctly' do
      filename = "#{SecureRandom.hex(6)}.md"
      write_file(filename, <<-EOF)
        # Hello there
        3. this is the first bullet
        2. this is the second bullet
        1. this is the third bullet
        4. this is the fourth bullet
      EOF

      vim.edit filename
      vim.type 'ggVG'
      vim.feedkeys 'gN'
      vim.write

      file_contents = IO.read(filename)

      expect(file_contents).to eq normalize_string_indent(<<-EOF)
        # Hello there
        1. this is the first bullet
        2. this is the second bullet
        3. this is the third bullet
        4. this is the fourth bullet\n
      EOF
    end
  end
end
