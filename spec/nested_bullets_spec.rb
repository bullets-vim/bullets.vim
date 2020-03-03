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
      vim.write

      file_contents = IO.read(filename)

      expect(file_contents).to eq normalize_string_indent(<<-TEXT)
          # Hello there
          I. this is the first bullet
          \tA. second bullet
          \t\t\t1. third bullet
          \t\t\t\ta. fourth bullet
          \t\t\t\t\ti. fifth bullet

      TEXT
    end

    it 'promotes an existing bullet' do
      filename = "#{SecureRandom.hex(6)}.txt"
      write_file(filename, <<-TEXT)
          # Hello there
          I. this is the first bullet
          \tA. second bullet
          \t\t1. third bullet
          \t\t\ta. fourth bullet
          \t\t\t\ti. fifth bullet
      TEXT

      vim.edit filename
      vim.normal '2j'
      vim.feedkeys '<<'
      vim.normal 'ji'
      vim.feedkeys '\<C-d>'
      vim.normal 'j'
      vim.feedkeys '<<<<'
      vim.normal 'j'
      vim.feedkeys '<<<<i'
      vim.feedkeys '\<C-d>\<C-d>'
      vim.write

      file_contents = IO.read(filename)

      expect(file_contents).to eq normalize_string_indent(<<-TEXT)
          # Hello there
          I. this is the first bullet
          II. second bullet
          \tA. third bullet
          \tB. fourth bullet
          III. fifth bullet

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
      vim.feedkeys '\<cr>'
      vim.feedkeys '\<C-t>\<C-t>'
      vim.type 'third bullet'
      vim.write

      file_contents = IO.read(filename)

      expect(file_contents).to eq normalize_string_indent(<<-TEXT)
          # Hello there
          I. this is the first bullet
          \tA. second bullet
          \t\t\t1. third bullet

      TEXT
    end

    it 'restarts numbering with multiple outlines' do
      filename = "#{SecureRandom.hex(6)}.txt"
      write_file(filename, <<-TEXT)
          # Hello there
          I. this is the first bullet
          \tA. second bullet
          \t\t1. third bullet
      TEXT

      vim.edit filename
      vim.normal 'GA'
      vim.feedkeys '\<cr>'
      vim.feedkeys '\<cr>'
      vim.type 'A. first bullet'
      vim.feedkeys '\<cr>'
      vim.feedkeys '\<C-t>'
      vim.type 'second bullet'
      vim.feedkeys '\<cr>'
      vim.feedkeys '\<C-t>'
      vim.type 'third bullet'
      vim.feedkeys '\<cr>'
      vim.feedkeys '\<cr>'
      vim.type '1. first bullet'
      vim.feedkeys '\<cr>'
      vim.feedkeys '\<C-t>'
      vim.type 'second bullet'
      vim.feedkeys '\<cr>'
      vim.feedkeys '\<C-t>'
      vim.type 'third bullet'
      vim.write

      file_contents = IO.read(filename)

      expect(file_contents).to eq normalize_string_indent(<<-TEXT)
        # Hello there
        I. this is the first bullet
        \tA. second bullet
        \t\t1. third bullet

        A. first bullet
        \t1. second bullet
        \t\ta. third bullet

        1. first bullet
        \ta. second bullet
        \t\ti. third bullet

      TEXT
    end

    it 'promotes an empty bullet' do
      filename = "#{SecureRandom.hex(6)}.txt"
      write_file(filename, <<-TEXT)
          # Hello there
          I. this is the first bullet
          \tA. second bullet
          \t\t1. third bullet
      TEXT

      vim.edit filename
      vim.normal 'GA'
      vim.feedkeys '\<cr>'
      vim.type 'fourth bullet'
      vim.feedkeys '\<cr>'
      vim.feedkeys '\<C-d>'
      vim.type 'fifth bullet'
      vim.feedkeys '\<cr>'
      vim.feedkeys '\<C-d>'
      vim.type 'sixth bullet'
      vim.feedkeys '\<cr>'
      vim.type 'seventh bullet'
      vim.write

      file_contents = IO.read(filename)

      expect(file_contents).to eq normalize_string_indent(<<-TEXT)
        # Hello there
        I. this is the first bullet
        \tA. second bullet
        \t\t1. third bullet
        \t\t2. fourth bullet
        \tB. fifth bullet
        II. sixth bullet
        III. seventh bullet

      TEXT
    end

    it 'works with custom outline level definitions' do
      filename = "#{SecureRandom.hex(6)}.txt"
      write_file(filename, <<-TEXT)
          # Hello there
      TEXT

      vim.edit filename
      vim.command "let g:bullets_outline_levels=['num','ABC','rom']"
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
      vim.type 'not a bullet'
      vim.feedkeys '\<cr>'
      vim.type 'seventh bullet'
      vim.feedkeys '\<cr>'
      vim.feedkeys '\<C-d>'
      vim.type 'eighth bullet'
      vim.feedkeys '\<cr>'
      vim.feedkeys '\<C-d>'
      vim.type 'ninth bullet'
      vim.feedkeys '\<cr>'
      vim.type 'tenth bullet'

      vim.write

      file_contents = IO.read(filename)

      expect(file_contents).to eq normalize_string_indent(<<-TEXT)
          # Hello there
          1. first bullet
          2. second bullet
          \tA. third bullet
          \tB. fourth bullet
          \t\ti. fifth bullet
          \t\tii. sixth bullet
          \t\t\tnot a bullet
          \t\tiii. seventh bullet
          \tC. eighth bullet
          3. ninth bullet
          4. tenth bullet

      TEXT
    end

    it 'promotes and demotes from different starting levels' do
      filename = "#{SecureRandom.hex(6)}.txt"
      write_file(filename, <<-TEXT)
          # Hello there
          1. this is the first bullet
          2. second bullet
      TEXT

      vim.edit filename
      vim.normal 'GA'
      vim.feedkeys '\<C-t>'
      vim.feedkeys '\<cr>'
      vim.type 'third bullet'
      vim.normal '3hi'
      vim.feedkeys '\<C-t>'
      vim.feedkeys '\<cr>'
      vim.feedkeys '\<esc>'
      vim.feedkeys '>>'
      vim.type 'anot a bullet'
      vim.feedkeys '\<cr>'
      vim.type 'fourth bullet'
      vim.feedkeys '\<cr>'
      vim.type 'fifth bullet'
      vim.feedkeys '\<C-d>'
      vim.feedkeys '\<esc>'
      vim.feedkeys '<<'
      vim.feedkeys 'i\<C-t>'
      vim.feedkeys '\<cr>'
      vim.feedkeys '\<cr>'
      vim.type 'i. sixth bullet'
      vim.feedkeys '\<cr>'
      vim.feedkeys '\<C-t>'
      vim.type 'not a bullet'
      vim.feedkeys '\<cr>'
      vim.type 'seventh bullet'

      vim.write

      file_contents = IO.read(filename)

      expect(file_contents).to eq normalize_string_indent(<<-TEXT)
          # Hello there
          1. this is the first bullet
          \ta. second bullet
          \t\ti. third bullet
          \t\t\tnot a bullet
          \t\tii. fourth bullet
          \tb. fifth bullet

          i. sixth bullet
          \tnot a bullet
          ii. seventh bullet

      TEXT
    end

    it 'does not nest below defined levels' do
      filename = "#{SecureRandom.hex(6)}.txt"
      write_file(filename, <<-TEXT)
        # Hello there
        I. this is the first bullet
        \tA. second bullet
        \t\t1. third bullet
        \t\t\ta. fourth bullet
        \t\t\t\ti. fifth bullet
        \t\t\t\tii. sixth bullet
      TEXT

      vim.edit filename
      vim.normal '6j'
      vim.feedkeys 'o'
      vim.feedkeys '\<C-t>'
      vim.type 'not a bullet'
      vim.feedkeys '\<cr>'
      vim.type 'seventh bullet'
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
        \t\t\t\t\tnot a bullet
        \t\t\t\tiii. seventh bullet

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

    it 'nested outlines handle standard bullets' do
      filename = "#{SecureRandom.hex(6)}.txt"
      write_file(filename, <<-TEXT)
        # Hello there
        1. this is the first bullet
        \t- standard bullet
      TEXT

      vim.edit filename
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
          \tB. third bullet
          \tC. fourth bullet
          \tD. fifth bullet
          \tE. sixth bullet
          \tF. seventh bullet
          \tG. eighth bullet
          \tH. ninth bullet
          \tI. tenth bullet
      TEXT

      vim.edit filename
      vim.normal 'GA'
      vim.feedkeys '\<cr>'
      vim.type 'eleventh bullet'
      vim.feedkeys '\<cr>'
      vim.feedkeys '\<C-d>'
      vim.type 'twelfth bullet'
      vim.feedkeys '\<cr>'
      vim.type 'thirteenth bullet'
      vim.feedkeys '\<cr>'
      vim.type 'fourteenth bullet'
      vim.feedkeys '\<C-t>'
      vim.feedkeys '\<cr>'
      vim.type 'fifteenth bullet'
      vim.feedkeys '\<C-t>'
      vim.feedkeys '\<cr>'
      vim.type 'sixteenth bullet'
      vim.feedkeys '\<C-t>'
      vim.feedkeys '\<cr>'
      vim.feedkeys '\<C-t>'
      vim.type 'seventeenth bullet'
      vim.feedkeys '\<cr>'
      vim.type 'eighteenth bullet'
      vim.write

      file_contents = IO.read(filename)

      expect(file_contents).to eq normalize_string_indent(<<-TEXT)
          # Hello there
          I. this is the first bullet
          \tA. second bullet
          \tB. third bullet
          \tC. fourth bullet
          \tD. fifth bullet
          \tE. sixth bullet
          \tF. seventh bullet
          \tG. eighth bullet
          \tH. ninth bullet
          \tI. tenth bullet
          \tJ. eleventh bullet
          II. twelfth bullet
          III. thirteenth bullet
          \tA. fourteenth bullet
          \t\t1. fifteenth bullet
          \t\t\ta. sixteenth bullet
          \t\t\t\ti. seventeenth bullet
          \t\t\t\tii. eighteenth bullet

      TEXT
    end
  end
end
