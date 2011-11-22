module Ohm
  module Slug
    module ClassMethods
      def [](id)
        super(id.to_i)
      end
    end

    def slug(str = to_s)
      ret = transcode(str)
      ret.gsub!("'", "")
      ret.gsub!(/\p{^Alnum}/u, " ")
      ret.strip!
      ret.gsub!(/\s+/, "-")
      ret.downcase
    end
    module_function :slug

    def transcode(str)
      begin
        # TODO: replace with a String#encode version which will
        # contain proper transliteration tables. For now, Iconv
        # still wins because we get that for free.
        v, $VERBOSE = $VERBOSE, nil
        require "iconv"
        $VERBOSE = v

        Iconv.iconv("ascii//translit//ignore", "utf-8", str)[0]
      rescue LoadError
        return str
      end
    end
    module_function :transcode

    def to_param
      "#{ id }-#{ slug }"
    end
  end
end