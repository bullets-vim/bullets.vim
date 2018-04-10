# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Bullets.vim' do
  describe 'inserting new bullets' do
    context 'on return key when cursor is at EOL' do
      it 'adds a new bullet if the previous line had a known bullet type' do
        filename = "#{SecureRandom.hex(6)}.md"
        write_file(filename, <<-TEXT)
          # Hello there
          - this is the first bullet
        TEXT

        vim.edit filename
        vim.type 'GA'
        vim.feedkeys '\<cr>'
        vim.type 'second bullet'
        vim.write

        file_contents = IO.read(filename)

        expect(file_contents).to eq normalize_string_indent(<<-TEXT)
          # Hello there
          - this is the first bullet
          - second bullet\n
        TEXT
      end

      it 'adds a new latex bullet' do
        filename = "#{SecureRandom.hex(6)}.md"
        write_file(filename, <<-TEXT)
        \\documentclass{article}
          \\begin{document}

          \\begin{itemize}
            \\item First item
        TEXT

        vim.edit filename
        vim.type 'GA'
        vim.feedkeys '\<cr>'
        vim.type 'Second item'
        vim.write

        file_contents = IO.read(filename)

        expect(file_contents).to eq normalize_string_indent(<<-TEXT)
        \\documentclass{article}
          \\begin{document}

          \\begin{itemize}
            \\item First item
            \\item Second item\n
        TEXT
      end

      it 'adds a pandoc bullet if the prev line had one' do
        filename = "#{SecureRandom.hex(6)}.md"
        write_file(filename, <<-TEXT)
          Hello there
          #. this is the first bullet
        TEXT

        vim.edit filename
        vim.type 'GA'
        vim.feedkeys '\<cr>'
        vim.type 'second bullet'
        vim.write

        file_contents = IO.read(filename)

        expect(file_contents).to eq normalize_string_indent(<<-TEXT)
          Hello there
          #. this is the first bullet
          #. second bullet\n
        TEXT
      end

      it 'adds an Org mode bullet if the prev line had one' do
        filename = "#{SecureRandom.hex(6)}.md"
        write_file(filename, <<-TEXT)
          Hello there
          **** this is the first bullet
        TEXT

        vim.edit filename
        vim.type 'GA'
        vim.feedkeys '\<cr>'
        vim.type 'second bullet'
        vim.write

        file_contents = IO.read(filename)

        expect(file_contents).to eq normalize_string_indent(<<-TEXT)
          Hello there
          **** this is the first bullet
          **** second bullet\n
        TEXT
      end

      it 'adds a new numeric bullet if the previous line had numeric bullet' do
        filename = "#{SecureRandom.hex(6)}.md"
        write_file(filename, <<-TEXT)
          # Hello there
          1) this is the first bullet
        TEXT

        vim.edit filename
        vim.type 'GA'
        vim.feedkeys '\<cr>'
        vim.type 'second bullet'
        vim.write

        file_contents = IO.read(filename)

        expect(file_contents).to eq normalize_string_indent(<<-TEXT)
          # Hello there
          1) this is the first bullet
          2) second bullet\n
        TEXT
      end

      it 'does not insert a new numeric bullet for decimal numbers' do
        filename = "#{SecureRandom.hex(6)}.md"
        write_file(filename, <<-TEXT)
          # Hello there
          3.14159 is an approximation of pi.
        TEXT

        vim.edit filename
        vim.type 'GA'
        vim.feedkeys '\<cr>'
        vim.type 'second line'
        vim.write

        file_contents = IO.read(filename)

        expect(file_contents).to eq normalize_string_indent(<<-TEXT)
          # Hello there
          3.14159 is an approximation of pi.
          second line\n
        TEXT
      end

      it 'adds a new roman numeral bullet' do
        filename = "#{SecureRandom.hex(6)}.md"
        write_file(filename, <<-TEXT)
          # Hello there
          I. this is the first bullet
        TEXT

        vim.edit filename
        vim.type 'GA'
        vim.feedkeys '\<cr>'
        vim.type 'second bullet'
        vim.feedkeys '\<cr>'
        vim.type 'third bullet'
        vim.feedkeys '\<cr>'
        vim.type 'fourth bullet'
        vim.feedkeys '\<cr>'
        vim.type 'fifth bullet'
        vim.write

        file_contents = IO.read(filename)

        expect(file_contents).to eq normalize_string_indent(<<-TEXT)
          # Hello there
          I. this is the first bullet
          II. second bullet
          III. third bullet
          IV. fourth bullet
          V. fifth bullet\n
        TEXT
      end

      it 'deletes the last bullet if it is empty' do
        filename = "#{SecureRandom.hex(6)}.md"
        write_file(filename, <<-TEXT)
          # Hello there
          - this is the first bullet
        TEXT

        vim.edit filename
        vim.type 'GA'
        vim.feedkeys '\<cr>'
        vim.feedkeys '\<cr>'
        vim.write

        file_contents = IO.read(filename)

        expect(file_contents.strip).to eq normalize_string_indent(<<-TEXT)
          # Hello there
          - this is the first bullet
        TEXT
      end

      it 'does not delete the last bullet when configured not to' do
        filename = "#{SecureRandom.hex(6)}.md"
        write_file(filename, <<-TEXT)
          # Hello there
          - this is the first bullet
        TEXT

        vim.command 'let g:bullets_delete_last_bullet_if_empty = 0'
        vim.edit filename
        vim.type 'GA'
        vim.feedkeys '\<cr>'
        vim.feedkeys '\<cr>'
        vim.write

        file_contents = IO.read(filename)

        expect(file_contents.strip).to eq normalize_string_indent(<<-TEXT)
          # Hello there
          - this is the first bullet
          -
        TEXT
      end
    end

    context 'on return key when cursor is not at EOL' do
      it 'splits the line and does not add a bullet' do
        filename = "#{SecureRandom.hex(6)}.md"
        write_file(filename, <<-TEXT)
          # Hello there
          - this is the first bullet
        TEXT

        vim.edit filename
        vim.type 'G$i'
        vim.feedkeys '\<cr>'
        vim.type 'second bullet'
        vim.write

        file_contents = IO.read(filename)

        expect(file_contents).to eq normalize_string_indent(<<-TEXT)
          # Hello there
          - this is the first bulle
          second bullett\n
        TEXT
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

      expect(buffer_content).to eq normalize_string_indent(<<-TEXT)
        # Hello there
        - this is the first bullet
        - this is the second bullet
      TEXT
    end
  end

  describe 're-numbering' do
    it 'renumbers a selected list correctly' do
      filename = "#{SecureRandom.hex(6)}.md"
      write_file(filename, <<-TEXT)
        # Hello there
        3. this is the first bullet
        2. this is the second bullet
        1. this is the third bullet
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
  end
end
