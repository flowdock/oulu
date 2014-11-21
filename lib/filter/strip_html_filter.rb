module Filter
  class StripHTMLFilter < HTML::Pipeline::Filter
    def call
      doc.text
    end
  end
end
