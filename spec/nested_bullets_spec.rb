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
          	A. second bullet
          			1. third bullet
          				a. fourth bullet
          					i. fifth bullet

      TEXT
    end

    it 'promotes an existing bullet' do
      filename = "#{SecureRandom.hex(6)}.txt"
      write_file(filename, <<-TEXT)
          # Hello there
          I. this is the first bullet
          	A. second bullet
          		1. third bullet
          			a. fourth bullet
          				i. fifth bullet
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
          	A. third bullet
          	B. fourth bullet
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

    it 'promotes an empty bullet' do
      filename = "#{SecureRandom.hex(6)}.txt"
      write_file(filename, <<-TEXT)
          # Hello there
          I. this is the first bullet
          	A. second bullet
          		1. third bullet
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
        	A. second bullet
        		1. third bullet
        		2. fourth bullet
        	B. fifth bullet
        II. sixth bullet
        III. seventh bullet

      TEXT
    end

    it 'does not nest below specified levels' do
      filename = "#{SecureRandom.hex(6)}.txt"
      write_file(filename, <<-TEXT)
        # Hello there
        I. this is the first bullet
        	A. second bullet
        		1. third bullet
        			a. fourth bullet
        				i. fifth bullet
        				ii. sixth bullet
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
        	A. second bullet
        		1. third bullet
        			a. fourth bullet
        				i. fifth bullet
        				ii. sixth bullet
        					not a bullet
        				iii. seventh bullet

      TEXT
    end
    it 'adds new nested bullets with correct alpha/roman numerals' do
      filename = "#{SecureRandom.hex(6)}.txt"
      write_file(filename, <<-TEXT)
          # Hello there
          I. this is the first bullet
          	A. second bullet
          	B. third bullet
          	C. fourth bullet
          	D. fifth bullet
          	E. sixth bullet
          	F. seventh bullet
          	G. eighth bullet
          	H. ninth bullet
          	I. tenth bullet
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
          	A. second bullet
          	B. third bullet
          	C. fourth bullet
          	D. fifth bullet
          	E. sixth bullet
          	F. seventh bullet
          	G. eighth bullet
          	H. ninth bullet
          	I. tenth bullet
          	J. eleventh bullet
          II. twelfth bullet
          III. thirteenth bullet
          	A. fourteenth bullet
          		1. fifteenth bullet
          			a. sixteenth bullet
          				i. seventeenth bullet
          				ii. eighteenth bullet

      TEXT
    end
  end
end
