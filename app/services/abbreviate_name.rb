class AbbreviateName
  attr_accessor :full_name

  CONJUNCTIONS_TO_REMOVE = ['at', 'of', 'in', 'on', 'by', 'and', 'for']
  ARTICLES_TO_REMOVE = ['the', 'a', 'an']

  def initialize(full_name)
    @full_name = full_name
  end

  def abbreviate(name_abbreviation_length)
    return @full_name if @full_name.length <= name_abbreviation_length

    clean_full_name = clean(@full_name)
    all_words = clean_full_name.split(' ')
    main_words = remove_inconsequential_words(all_words)

    word_hash = main_words.each_with_index.map do |word, i|
      {
        full_word: word,
        short_word: word,
        i: i
      }
    end

    until word_hash.map { |word| word[:short_word].length }.reduce(:+) <= name_abbreviation_length
      word_hash.sort_by! { |hash| hash[:short_word].length }
      longest_word = word_hash.pop
      longest_word[:short_word] = longest_word[:short_word][0..-2]
      word_hash.push(longest_word)
    end

    word_hash.sort_by! { |word| word[:i] }
    capitalized_short_words = word_hash.map { |word| word[:short_word].capitalize }
    capitalized_short_words.join('')
  end

  private

  def clean(full_name)
    clean_name = full_name.gsub(/[\.\#\&'":\*]/, '')
    clean_name.gsub!(/[\_\-\/\+\(\)@]/, ' ')
    clean_name.squeeze(' ')
    clean_name
  end

  def remove_inconsequential_words(words)
    words.reject! { |word| CONJUNCTIONS_TO_REMOVE.include?(word.downcase) }
    words.reject! { |word| ARTICLES_TO_REMOVE.include?(word.downcase) }
    words
  end

  def shorten_word_to(word, target_length)
    word[0..(target_length - 1)]
  end
end
