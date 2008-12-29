class RGrep
  class Annotation < Struct.new(:line, :text)
    def to_s(options={})
      s = "[%3d] " % line
      s << text.to_s
    end
  end

  def self.enumerate(tag, options={})
    extractor = new(tag)
    extractor.display(extractor.find, options)
  end

  attr_reader :tag

  def initialize(tag)
    @tag = tag
  end

  def find(dirs=%w(app lib test))
    dirs.inject({}) { |h, dir| h.update(find_in(dir)) }
  end

  def find_in(dir)
    results = {}

    Dir.glob("#{dir}/*") do |item|
      next if File.basename(item)[0] == ?.

      if File.directory?(item)
        results.update(find_in(item))
      elsif item =~ /\.(builder|(r(?:b|xml|js)|rhtml|erb))$/
        results.update(extract_annotations_from(item, /#{tag}/))
      end
    end

    results
  end

  def extract_annotations_from(file, pattern)
    lineno = 0
    result = File.readlines(file).inject([]) do |list, line|
      lineno += 1
      next list unless line =~ pattern
      list << Annotation.new(lineno, line)
    end
    result.empty? ? {} : { file => result }
  end

  # Prints the mapping from filenames to annotations in +results+ ordered by filename.
  # The +options+ hash is passed to each annotation's +to_s+.
  def display(results, options={})
    results.keys.sort.each do |file|
      puts "#{file}:"
      results[file].each do |note|
        puts " * #{note.to_s(options)}"
      end
      puts
    end
  end
end

RGrep.enumerate ARGV.first.to_s, :tag => true

