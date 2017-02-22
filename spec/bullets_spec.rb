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

      it 'adds a new latex bullet' do
        filename = "#{SecureRandom.hex(6)}.md"
        write_file(filename, <<-EOF)
        \\documentclass{article}
          \\begin{document}

          \\begin{itemize}
            \\item First item
        EOF

        vim.edit filename
        vim.type 'GA'
        vim.feedkeys '\<cr>'
        vim.type 'Second item'
        vim.write

        file_contents = IO.read(filename)

        expect(file_contents).to eq normalize_string_indent(<<-EOF)
        \\documentclass{article}
          \\begin{document}

          \\begin{itemize}
            \\item First item
            \\item Second item\n
        EOF
      end

      it 'adds a new numeric bullet if the previous line had numeric bullet' do
        filename = "#{SecureRandom.hex(6)}.md"
        write_file(filename, <<-EOF)
          # Hello there
          1) this is the first bullet
        EOF

        vim.edit filename
        vim.type 'GA'
        vim.feedkeys '\<cr>'
        vim.type 'second bullet'
        vim.write

        file_contents = IO.read(filename)

        expect(file_contents).to eq normalize_string_indent(<<-EOF)
          # Hello there
          1) this is the first bullet
          2) second bullet\n
        EOF
      end

      it 'deletes the last bullet if it is empty' do
        filename = "#{SecureRandom.hex(6)}.md"
        write_file(filename, <<-EOF)
          # Hello there
          - this is the first bullet
        EOF

        vim.edit filename
        vim.type 'GA'
        vim.feedkeys '\<cr>'
        vim.feedkeys '\<cr>'
        vim.write

        file_contents = IO.read(filename)

        expect(file_contents.strip).to eq normalize_string_indent(<<-EOF)
          # Hello there
          - this is the first bullet
        EOF
      end

      it 'does not delete the last bullet when configured not to' do
        filename = "#{SecureRandom.hex(6)}.md"
        write_file(filename, <<-EOF)
          # Hello there
          - this is the first bullet
        EOF

        vim.command 'let g:bullets_delete_last_bullet_if_empty = 0'
        vim.edit filename
        vim.type 'GA'
        vim.feedkeys '\<cr>'
        vim.feedkeys '\<cr>'
        vim.write

        file_contents = IO.read(filename)

        expect(file_contents.strip).to eq normalize_string_indent(<<-EOF)
          # Hello there
          - this is the first bullet
          -
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

  describe 'filetypes' do
    it 'creates mapping for bullets on empty buffer if configured' do
      vim.command 'new'
      vim.insert '# Hello there'
      vim.feedkeys '\<cr>'
      vim.type '- this is the first bullet'
      vim.feedkeys '\<cr>'
      vim.type 'this is the second bullet'

      buffer_content = vim.echo("join(getbufline(bufname(''), 1, '$'), '\n')")

      expect(buffer_content).to eq normalize_string_indent(<<-EOF)
        # Hello there
        - this is the first bullet
        - this is the second bullet
      EOF
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
