# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Bullets.vim' do
  describe 'alphabetic bullets' do
    it 'adds a new upper case bullet' do
      filename = "#{SecureRandom.hex(6)}.txt"
      write_file(filename, <<-TEXT)
          # Hello there
          A. this is the first bullet
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
      vim.feedkeys '\<cr>'
      vim.type 'sixth bullet'
      vim.feedkeys '\<cr>'
      vim.type 'seventh bullet'
      vim.feedkeys '\<cr>'
      vim.type 'eighth bullet'
      vim.feedkeys '\<cr>'
      vim.type 'ninth bullet'
      vim.feedkeys '\<cr>'
      vim.type 'tenth bullet'
      vim.write

      file_contents = IO.read(filename)

      expect(file_contents).to eq normalize_string_indent(<<-TEXT)
          # Hello there
          A. this is the first bullet
          B. second bullet
          C. third bullet
          D. fourth bullet
          E. fifth bullet
          F. sixth bullet
          G. seventh bullet
          H. eighth bullet
          I. ninth bullet
          J. tenth bullet

      TEXT
    end

    it 'adds a new lower case bullet' do
      filename = "#{SecureRandom.hex(6)}.txt"
      write_file(filename, <<-TEXT)
          # Hello there
          a. this is the first bullet
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
      vim.feedkeys '\<cr>'
      vim.type 'sixth bullet'
      vim.feedkeys '\<cr>'
      vim.type 'seventh bullet'
      vim.feedkeys '\<cr>'
      vim.type 'eighth bullet'
      vim.feedkeys '\<cr>'
      vim.type 'ninth bullet'
      vim.feedkeys '\<cr>'
      vim.type 'tenth bullet'
      vim.write

      file_contents = IO.read(filename)

      expect(file_contents).to eq normalize_string_indent(<<-TEXT)
          # Hello there
          a. this is the first bullet
          b. second bullet
          c. third bullet
          d. fourth bullet
          e. fifth bullet
          f. sixth bullet
          g. seventh bullet
          h. eighth bullet
          i. ninth bullet
          j. tenth bullet

      TEXT
    end

    it 'adds a new bullet and loops at z' do
      filename = "#{SecureRandom.hex(6)}.txt"
      write_file(filename, <<-TEXT)
          # Hello there
          y. this is the first bullet
      TEXT

      vim.edit filename
      vim.command('let g:bullets_renumber_on_change=0')
      vim.type 'GA'
      vim.feedkeys '\<cr>'
      vim.type 'second bullet'
      vim.feedkeys '\<cr>'
      vim.type 'third bullet'
      vim.feedkeys '\<cr>'
      vim.feedkeys '\<cr>'
      vim.type 'AY. fourth bullet'
      vim.feedkeys '\<cr>'
      vim.type 'fifth bullet'
      vim.feedkeys '\<cr>'
      vim.type 'sixth bullet'
      vim.write

      file_contents = IO.read(filename)

      expect(file_contents).to eq normalize_string_indent(<<-TEXT)
          # Hello there
          y. this is the first bullet
          z. second bullet
          aa. third bullet
          AY. fourth bullet
          AZ. fifth bullet
          BA. sixth bullet\n
      TEXT
    end

    it 'does not add a new bullet when mixed case' do
      test_bullet_inserted('not a bullet', <<-INIT, <<-EXPECTED)
        # Hello there
        Ab. this is the first bullet
      INIT
        # Hello there
        Ab. this is the first bullet
        not a bullet
      EXPECTED
    end

    # it 'correctly numbers after wrapped lines starting with short words' do
    # # TODO: maybe take guidance from Pandoc and require two spaces after the
    # closure to allow us to differentiate between bullets and abbreviations
    # and words. Might also consider only allowing single letters.
    #   test_bullet_inserted('second bullet', <<-INIT, <<-EXPECTED)
    #     # Hello there
    #     a. first bullet might not catch
    #        me. second line.
    #   INIT
    #     # Hello there
    #     a. first bullet might not catch
    #     \tme. second line.
    #     b. second bullet
    #   EXPECTED
    # end

    # it 'correctly numbers after lines beginning with initialized names' do
    # # TODO: maybe take guidance from Pandoc and require two spaces after the
    # closure to allow us to differentiate between bullets and abbreviations
    # and words. Might also consider only allowing single letters.
    #   test_bullet_inserted('Second bullet', <<-INIT, <<-EXPECTED)
    #     # Hello there
    #     I. The first president of the USA was
    #        G. Washington.
    #   INIT
    #     # Hello there
    #     I. The first president of the USA was
    #        G. Washington.
    #     II. Second bullet
    #   EXPECTED
    # end

    describe 'g:bullets_max_alpha_characters' do
      it 'stops adding items after configured max (default 2)' do
        filename = "#{SecureRandom.hex(6)}.txt"
        write_file(filename, <<-TEXT)
          # Hello there
          zy. this is the first bullet
        TEXT

        vim.edit filename
        vim.command('let g:bullets_renumber_on_change=0')
        vim.type 'GA'
        vim.feedkeys '\<cr>'
        vim.type 'second bullet'
        vim.feedkeys '\<cr>'
        vim.type 'not a bullet'
        vim.write

        file_contents = IO.read(filename)

        expect(file_contents).to eq normalize_string_indent(<<-TEXT)
          # Hello there
          zy. this is the first bullet
          zz. second bullet
          not a bullet\n
        TEXT
      end

      it 'does not bullets if configured as 0' do
        filename = "#{SecureRandom.hex(6)}.txt"
        write_file(filename, <<-TEXT)
          # Hello there
          a. this is the first bullet
        TEXT

        vim.command 'let g:bullets_max_alpha_characters = 0'
        vim.edit filename
        vim.type 'GA'
        vim.feedkeys '\<cr>'
        vim.type 'not a bullet'
        vim.write

        file_contents = IO.read(filename)

        expect(file_contents).to eq normalize_string_indent(<<-TEXT)
          # Hello there
          a. this is the first bullet
          not a bullet\n
        TEXT
      end
    end
  end
end
