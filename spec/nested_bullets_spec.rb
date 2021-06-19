# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Bullets.vim' do
  describe 'nested bullets' do
    it 'demotes an existing bullet' do
      filename = "#{SecureRandom.hex(6)}.txt"
      write_file(filename, <<-TEXT)
          # Hello there
          I. this is the first bullet
          II. second bullet
          III. third bullet
          IV. fourth bullet
          V. fifth bullet
          VI. sixth bullet
          VII. seventh bullet
          VIII. eighth bullet
          IX. ninth bullet
      TEXT

      vim.edit filename
      vim.normal '2ji'
      vim.feedkeys '\<C-t>'
      vim.normal 'j'
      vim.feedkeys '>>>>>>'
      vim.normal 'j'
      vim.feedkeys '>>>>>>>>'
      vim.normal 'j'
      vim.feedkeys '>>>>>>>>>>'
      vim.normal 'j'
      vim.feedkeys '>>>>>>>>'
      vim.feedkeys '>>>>'
      vim.normal 'j'
      vim.feedkeys '>>>>>>>>'
      vim.feedkeys '>>>>>>'
      vim.normal 'j'
      vim.feedkeys '>>>>>>>>'
      vim.feedkeys '>>>>>>>>'
      vim.normal 'j'
      vim.feedkeys '>>>>>>>>'
      vim.feedkeys '>>>>>>>>>>'
      vim.write

      file_contents = IO.read(filename)

      expect(file_contents).to eq normalize_string_indent(<<-TEXT)
          # Hello there
          I. this is the first bullet
          \tA. second bullet
          \t\t\t1. third bullet
          \t\t\t\ta. fourth bullet
          \t\t\t\t\ti. fifth bullet
          \t\t\t\t\t\t- sixth bullet
          \t\t\t\t\t\t\t* seventh bullet
          \t\t\t\t\t\t\t\t+ eighth bullet
          \t\t\t\t\t\t\t\t\t+ ninth bullet

      TEXT
    end

    it 'promotes an existing bullet' do
      filename = "#{SecureRandom.hex(6)}.txt"
      write_file(filename, <<-TEXT)
          # Hello there
          I. this is the first bullet
          \tA. second bullet
          \t\t\t1. third bullet
          \t\t\t\ta. fourth bullet
          \t\t\t\t\ti. fifth bullet
          \t\t\t\t\t\t- sixth bullet
          \t\t\t\t\t\t\t* seventh bullet
          \t\t\t\t\t\t\t\t+ eighth bullet
      TEXT

      vim.edit filename
      vim.normal '2j'
      vim.feedkeys '<<'
      vim.normal 'ji'
      vim.feedkeys '\<C-d>'
      vim.feedkeys '\<C-d>'
      vim.normal 'j'
      vim.feedkeys '<<<<<<'
      vim.normal 'j'
      vim.feedkeys '<<<<<<'
      vim.feedkeys '<<<<'
      vim.normal 'j'
      vim.feedkeys '<<<<<<'
      vim.feedkeys '<<<<<<'
      vim.normal 'j'
      vim.feedkeys '<<<<<<'
      vim.feedkeys '<<<<<<<<'
      vim.normal 'j'
      vim.feedkeys '<<<<<<'
      vim.feedkeys '<<<<<<'
      vim.feedkeys '<<<<'
      vim.write

      file_contents = IO.read(filename)

      expect(file_contents).to eq normalize_string_indent(<<-TEXT)
          # Hello there
          I. this is the first bullet
          II. second bullet
          \tA. third bullet
          \tB. fourth bullet
          III. fifth bullet
          IV.  sixth bullet
          V.   seventh bullet
          VI.  eighth bullet

      TEXT
    end

    it 'demotes an empty bullet' do
      filename = "#{SecureRandom.hex(6)}.txt"
      write_file(filename, <<-TEXT)
          # Hello there
          I. this is the first bullet
      TEXT

      vim.edit filename
      vim.normal 'GA'
      vim.feedkeys '\<cr>'
      vim.feedkeys '\<C-t>'
      vim.type 'second bullet'
      vim.write

      file_contents = IO.read(filename)

      expect(file_contents).to eq normalize_string_indent(<<-TEXT)
          # Hello there
          I. this is the first bullet
          \tA. second bullet

      TEXT
    end

    it 'promotes an empty bullet' do
      filename = "#{SecureRandom.hex(6)}.txt"
      write_file(filename, <<-TEXT)
          # Hello there
          I. this is the first bullet
          \tA. second bullet
      TEXT

      vim.edit filename
      vim.normal 'GA'
      vim.feedkeys '\<cr>'
      vim.feedkeys '\<C-d>'
      vim.type 'third bullet'
      vim.write

      file_contents = IO.read(filename)

      expect(file_contents).to eq normalize_string_indent(<<-TEXT)
          # Hello there
          I. this is the first bullet
          \tA. second bullet
          II. third bullet

      TEXT
    end

    it 'restarts numbering with multiple outlines' do
      filename = "#{SecureRandom.hex(6)}.txt"
      write_file(filename, <<-TEXT)
          # Hello there
          I. this is the first bullet
          \tA. second bullet
      TEXT

      vim.edit filename
      vim.normal 'GA'
      vim.feedkeys '\<cr>'
      vim.feedkeys '\<cr>'
      vim.feedkeys '\<cr>'
      vim.type 'A. first bullet'
      vim.feedkeys '\<cr>'
      vim.feedkeys '\<C-t>'
      vim.type 'second bullet'
      vim.write

      file_contents = IO.read(filename)

      expect(file_contents).to eq normalize_string_indent(<<-TEXT)
          # Hello there
          I. this is the first bullet
          \tA. second bullet

          A. first bullet
          \t1. second bullet

      TEXT
    end

    it 'works with custom outline level definitions' do
      filename = "#{SecureRandom.hex(6)}.txt"
      write_file(filename, <<-TEXT)
          # Hello there
      TEXT

      vim.edit filename
      vim.command "let g:bullets_outline_levels=['num','ABC','std*']"
      vim.normal 'GA'
      vim.feedkeys '\<cr>'
      vim.type '1. first bullet'
      vim.feedkeys '\<cr>'
      vim.type 'second bullet'
      vim.feedkeys '\<cr>'
      vim.feedkeys '\<C-t>'
      vim.type 'third bullet'
      vim.feedkeys '\<cr>'
      vim.type 'fourth bullet'
      vim.feedkeys '\<cr>'
      vim.feedkeys '\<C-t>'
      vim.type 'fifth bullet'
      vim.feedkeys '\<cr>'
      vim.type 'sixth bullet'
      vim.feedkeys '\<cr>'
      vim.feedkeys '\<C-t>'
      vim.type 'seventh bullet'
      vim.feedkeys '\<cr>'
      vim.type 'eighth bullet'
      vim.feedkeys '\<cr>'
      vim.feedkeys '\<C-d>'
      vim.feedkeys '\<C-d>'
      vim.type 'ninth bullet'
      vim.feedkeys '\<cr>'
      vim.feedkeys '\<C-d>'
      vim.type 'tenth bullet'
      vim.feedkeys '\<cr>'
      vim.type 'eleventh bullet'

      vim.write

      file_contents = IO.read(filename)

      expect(file_contents).to eq normalize_string_indent(<<-TEXT)
          # Hello there
          1. first bullet
          2. second bullet
          \tA. third bullet
          \tB. fourth bullet
          \t\t* fifth bullet
          \t\t* sixth bullet
          \t\t\t* seventh bullet
          \t\t\t* eighth bullet
          \tC. ninth bullet
          3. tenth bullet
          4. eleventh bullet

      TEXT
    end

    it 'promotes and demotes from different starting levels' do
      filename = "#{SecureRandom.hex(6)}.txt"
      write_file(filename, <<-TEXT)
          # Hello there
          1. this is the first bullet
          \ta. second bullet
      TEXT

      vim.edit filename
      vim.normal 'GA'
      vim.feedkeys '\<C-d>'
      vim.feedkeys '\<cr>'
      vim.feedkeys '\<C-t>'
      vim.type 'third bullet'
      vim.feedkeys '\<cr>'
      vim.feedkeys '\<cr>'
      vim.type '+ fourth bullet'
      vim.feedkeys '\<cr>'
      vim.feedkeys '\<C-t>'
      vim.type 'fifth bullet'
      vim.feedkeys '\<cr>'
      vim.feedkeys '\<cr>'
      vim.type '* sixth bullet'
      vim.feedkeys '\<cr>'
      vim.type 'seventh bullet'
      vim.feedkeys '\<C-t>'

      vim.write

      file_contents = IO.read(filename)

      expect(file_contents).to eq normalize_string_indent(<<-TEXT)
          # Hello there
          1. this is the first bullet
          2. second bullet
          \ta. third bullet
          + fourth bullet
          \t+ fifth bullet
          * sixth bullet
          \t+ seventh bullet

      TEXT
    end

    it 'does not nest beyond defined levels' do
      filename = "#{SecureRandom.hex(6)}.txt"
      write_file(filename, <<-TEXT)
          # Hello there
          I. this is the first bullet
          \tA. second bullet
          \t\t1. third bullet
          \t\t\ta. fourth bullet
          \t\t\t\ti. fifth bullet
          \t\t\t\tii. sixth bullet
          \t\t\t\t\t- seventh bullet
          \t\t\t\t\t\t* eighth bullet
          \t\t\t\t\t\t\t+ ninth bullet
      TEXT

      vim.edit filename
      vim.normal 'GA'
      vim.feedkeys '\<cr>'
      vim.feedkeys '\<C-t>'
      vim.type 'tenth bullet'
      vim.feedkeys '\<cr>'
      vim.type 'eleventh bullet'
      vim.write

      file_contents = IO.read(filename)

      expect(file_contents).to eq normalize_string_indent(<<-TEXT)
          # Hello there
          I. this is the first bullet
          \tA. second bullet
          \t\t1. third bullet
          \t\t\ta. fourth bullet
          \t\t\t\ti. fifth bullet
          \t\t\t\tii. sixth bullet
          \t\t\t\t\t- seventh bullet
          \t\t\t\t\t\t* eighth bullet
          \t\t\t\t\t\t\t+ ninth bullet
          \t\t\t\t\t\t\t\t+ tenth bullet
          \t\t\t\t\t\t\t\t+ eleventh bullet

      TEXT
    end

    it 'removes bullet when promoting top level bullet' do
      filename = "#{SecureRandom.hex(6)}.txt"
      write_file(filename, <<-TEXT)
          # Hello there
          A. this is the first bullet

          I. second bullet
          \tA. third bullet
      TEXT

      vim.edit filename
      vim.normal 'j'
      vim.feedkeys '<<'
      vim.normal '3ji'
      vim.feedkeys '\<C-d>'
      vim.feedkeys '\<C-d>'
      vim.write

      file_contents = IO.read(filename)

      expect(file_contents).to eq normalize_string_indent(<<-TEXT)
          # Hello there
          this is the first bullet

          I. second bullet
          third bullet

      TEXT
    end

    it 'handle standard bullets when they are not in outline list' do
      filename = "#{SecureRandom.hex(6)}.txt"
      write_file(filename, <<-TEXT)
          # Hello there
          1. this is the first bullet
          \t- standard bullet
      TEXT

      vim.edit filename
      vim.command "let g:bullets_outline_levels=['num','ABC']"
      vim.normal 'GA'
      vim.feedkeys '\<cr>'
      vim.type 'second standard bullet'
      vim.feedkeys '\<cr>'
      vim.feedkeys '\<C-d>'
      vim.type 'second bullet'
      vim.feedkeys '\<cr>'
      vim.type 'third bullet'
      vim.write

      file_contents = IO.read(filename)

      expect(file_contents).to eq normalize_string_indent(<<-TEXT)
          # Hello there
          1. this is the first bullet
          \t- standard bullet
          \t- second standard bullet
          2. second bullet
          3. third bullet

      TEXT
    end

    it 'adds new nested bullets with correct alpha/roman numerals' do
      filename = "#{SecureRandom.hex(6)}.txt"
      write_file(filename, <<-TEXT)
          # Hello there
          I. this is the first bullet
          \tA. second bullet
      TEXT

      vim.edit filename
      vim.normal 'GA'
      vim.feedkeys '\<cr>'
      vim.type 'third bullet'
      vim.feedkeys '\<C-t>'
      vim.feedkeys '\<cr>'
      vim.type 'fourth bullet'
      vim.feedkeys '\<C-t>'
      vim.feedkeys '\<cr>'
      vim.type 'fifth bullet'
      vim.feedkeys '\<C-t>'
      vim.feedkeys '\<cr>'
      vim.type 'sixth bullet'
      vim.feedkeys '\<C-t>'
      vim.feedkeys '\<cr>'
      vim.type 'seventh bullet'
      vim.feedkeys '\<cr>'
      vim.type 'eighth bullet'
      vim.feedkeys '\<C-d>'
      vim.feedkeys '\<cr>'
      vim.type 'ninth bullet'
      vim.feedkeys '\<C-d>'
      vim.feedkeys '\<cr>'
      vim.type 'tenth bullet'
      vim.feedkeys '\<C-d>'
      vim.feedkeys '\<cr>'
      vim.type 'eleventh bullet'
      vim.feedkeys '\<C-d>'
      vim.feedkeys '\<cr>'
      vim.type 'twelfth bullet'
      vim.feedkeys '\<C-d>'
      vim.write

      file_contents = IO.read(filename)

      expect(file_contents).to eq normalize_string_indent(<<-TEXT)
          # Hello there
          I. this is the first bullet
          \tA. second bullet
          \t\t1. third bullet
          \t\t\ta. fourth bullet
          \t\t\t\ti. fifth bullet
          \t\t\t\t\t- sixth bullet
          \t\t\t\t\t- seventh bullet
          \t\t\t\tii. eighth bullet
          \t\t\tb. ninth bullet
          \t\t2. tenth bullet
          \tB. eleventh bullet
          II. twelfth bullet

      TEXT
    end

    it 'changes levels in visual mode' do
      filename = "#{SecureRandom.hex(6)}.txt"
      write_file(filename, <<-TEXT)
          # Hello there
          1. first bullet
          \ta. second bullet
          \tb. third bullet
          \t\t* fourth bullet
          \t\t* fifth bullet
          \t\t\tsixth bullet
          \t\t* seventh bullet
          2. eighth bullet
          \t\ta. ninth bullet
          \ta. tenth bullet
          \tb. eleventh bullet
          3. twelfth bullet
          \t thirteenth bullet
          \ta. fourteenth bullet
          \t\t* fifteenth bullet
          4. sixteenth bullet
      TEXT

      vim.edit filename
      vim.command "let g:bullets_outline_levels=['num','abc','std*']"
      vim.normal '3jv'
      vim.feedkeys '<'
      vim.normal 'jv2j'
      vim.feedkeys '<'
      vim.normal 'jvj'
      vim.feedkeys '>'
      vim.normal 'jvj'
      vim.feedkeys '<'
      vim.feedkeys '<'
      vim.normal 'jv'
      vim.feedkeys '>'
      vim.normal '3jv2j'
      vim.feedkeys '>'
      vim.feedkeys '>'
      vim.write

      file_contents = IO.read(filename)

      expect(file_contents).to eq normalize_string_indent(<<-TEXT)
          # Hello there
          1. first bullet
          \ta. second bullet
          2. third bullet
          \ta. fourth bullet
          \tb. fifth bullet
          \t\tsixth bullet
          \t\t\t* seventh bullet
          \tc. eighth bullet
          3. ninth bullet
          tenth bullet
          \t\ta. eleventh bullet
          4. twelfth bullet
          \t thirteenth bullet
          \t\t\ta. fourteenth bullet
          \t\t\t\t* fifteenth bullet
          \t\ta. sixteenth bullet

      TEXT
    end

    it 'add and change bullets with multiple line spacing and wrapped lines' do
      filename = "#{SecureRandom.hex(6)}.txt"
      write_file(filename, <<-TEXT)
          # Hello there
          I. this is the first bullet
      TEXT

      vim.edit filename
      vim.command 'let g:bullets_line_spacing=2'
      vim.normal 'GA'
      vim.feedkeys '\<cr>'
      vim.type 'second bullet'
      vim.feedkeys '\<cr>'
      vim.feedkeys '\<C-t>'
      vim.type 'third bullet'
      vim.feedkeys '\<cr>'
      vim.normal 'dd'
      vim.insert '	wrapped bullet'
      vim.feedkeys '\<cr>'
      vim.type 'fourth bullet'
      vim.write

      file_contents = IO.read(filename)

      expect(file_contents).to eq normalize_string_indent(<<-TEXT)
          # Hello there
          I. this is the first bullet

          II. second bullet

          \tA. third bullet
          \twrapped bullet

          \tB. fourth bullet

      TEXT
    end
  end
end
