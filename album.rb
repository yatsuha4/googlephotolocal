#
class Album
  #
  def initialize(json)
    @json = json
    @items = Array.new
  end

  #
  def id
    return @json['id']
  end

  #
  def title
    return @json['title']
  end

  #
  def writeable?
    return @json['isWriteable']
  end

  #
  attr_accessor :items

  #
  def to_s
    return "#{title} (#{@items.size})"
  end
end
