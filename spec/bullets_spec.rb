# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Bullets.vim' do
  describe 'inserting new bullets' do
    context 'on return key when cursor is not at EOL' do
      it 'splits the line and does not add a bullet' do
        filename = "#{SecureRandom.hex(6)}.txt"
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

    context 'on return key when cursor is at EOL' do
      it 'adds a new bullet if the previous line had a known bullet type' do
        test_bullet_inserted('do that', <<-INIT, <<-EXPECTED)
          # Hello there
          - do this
        INIT
          # Hello there
          - do this
          - do that
        EXPECTED
      end

      it 'adds a new latex bullet' do
        test_bullet_inserted('Second item', <<-INIT, <<-EXPECTED)
        \\documentclass{article}
          \\begin{document}

          \\begin{itemize}
            \\item First item
        INIT
        \\documentclass{article}
          \\begin{document}

          \\begin{itemize}
            \\item First item
            \\item Second item
        EXPECTED
      end

      it 'adds a pandoc bullet if the prev line had one' do
        test_bullet_inserted('second bullet', <<-INIT, <<-EXPECTED)
          Hello there
          #. this is the first bullet
        INIT
          Hello there
          #. this is the first bullet
          #. second bullet
        EXPECTED
      end

      it 'adds an Org mode bullet if the prev line had one' do
        test_bullet_inserted('second bullet', <<-INIT, <<-EXPECTED)
          Hello there
          **** this is the first bullet
        INIT
          Hello there
          **** this is the first bullet
          **** second bullet
        EXPECTED
      end

      it 'adds a new numeric bullet if the previous line had numeric bullet' do
        test_bullet_inserted('second bullet', <<-INIT, <<-EXPECTED)
          # Hello there
          1) this is the first bullet
        INIT
          # Hello there
          1) this is the first bullet
          2) second bullet
        EXPECTED
      end

      it 'adds a new numeric bullet with right padding' do
        test_bullet_inserted('second bullet', <<-INIT, <<-EXPECTED)
          # Hello there
          1.  this is the first bullet
        INIT
          # Hello there
          1.  this is the first bullet
          2.  second bullet
        EXPECTED
      end

      it 'maintains total bullet width from 9. to 10. with reduced padding' do
        vim.command('let g:bullets_renumber_on_change=0')
        test_bullet_inserted('second bullet', <<-INIT, <<-EXPECTED)
          # Hello there
          9.  this is the first bullet
        INIT
          # Hello there
          9.  this is the first bullet
          10. second bullet
        EXPECTED
      end

      it 'adds a new - bullet with right padding' do
        test_bullet_inserted('second bullet', <<-INIT, <<-EXPECTED)
          # Hello there
          -   this is the first bullet
        INIT
          # Hello there
          -   this is the first bullet
          -   second bullet
        EXPECTED
      end

      it 'does not insert a new numeric bullet for decimal numbers' do
        test_bullet_inserted('second line', <<-INIT, <<-EXPECTED)
          # Hello there
          3.14159 is an approximation of pi.
        INIT
          # Hello there
          3.14159 is an approximation of pi.
          second line
        EXPECTED
      end

      it 'adds a new roman numeral bullet' do
        filename = "#{SecureRandom.hex(6)}.txt"
        write_file(filename, <<-TEXT)
          # Hello there
          I. this is the first bullet
        TEXT

        vim.command 'let g:bullets_pad_right = 0'
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

      it 'adds a new lowercase roman numeral bullet' do
        filename = "#{SecureRandom.hex(6)}.txt"
        write_file(filename, <<-TEXT)
          # Hello there
          i. this is the first bullet
        TEXT

        vim.command 'let g:bullets_pad_right = 0'
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
          i. this is the first bullet
          ii. second bullet
          iii. third bullet
          iv. fourth bullet
          v. fifth bullet\n
        TEXT
      end

      it 'does not confuse with the "ignorecase" option' do
        vim.command 'set ignorecase'
        test_bullet_inserted('second line', <<-INIT, <<-EXPECTED)
          # Hello there
          Vi. this is the first line
        INIT
          # Hello there
          Vi. this is the first line
          second line
        EXPECTED
      end

      it 'does not insert a new roman bullets without following spaces' do
        test_bullet_inserted('second line', <<-INIT, <<-EXPECTED)
          # Hello there
          m.example.com is a site.
        INIT
          # Hello there
          m.example.com is a site.
          second line
        EXPECTED
      end

      it 'does not insert a new roman bullets for invalid roman numbers' do
        filename = "#{SecureRandom.hex(6)}.txt"
        write_file(filename, <<-TEXT)
          # Hello there
          LID. the first line
        TEXT

        vim.edit filename
        vim.type 'GA'
        vim.feedkeys '\<cr>'
        vim.type 'second line'
        vim.feedkeys '\<cr>'
        vim.type 'vim. third line'
        vim.feedkeys '\<cr>'
        vim.type 'fourth line'
        vim.write

        file_contents = IO.read(filename)

        expect(file_contents).to eq normalize_string_indent(<<-TEXT)
          # Hello there
          LID. the first line
          second line
          vim. third line
          fourth line\n
        TEXT
      end

      it 'deletes the last bullet if it is empty' do
        filename = "#{SecureRandom.hex(6)}.txt"
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
        filename = "#{SecureRandom.hex(6)}.txt"
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
  end
end
