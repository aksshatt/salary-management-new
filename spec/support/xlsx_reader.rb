require "zip"
require "nokogiri"

# Reads the first sheet of an .xlsx file (a zip of XML files) for specs:
# each cell becomes [value, type] where type is :number, :string or :formula.
module XlsxReader
  def read_xlsx(data)
    rows = nil
    Zip::File.open_buffer(StringIO.new(data)) do |zip|
      shared = shared_strings(zip)
      sheet = Nokogiri::XML(zip.read("xl/worksheets/sheet1.xml")).remove_namespaces!
      rows = sheet.xpath("//sheetData/row").map { |row| row.xpath("c").map { |cell| read_cell(cell, shared) } }
    end
    rows
  end

  private
    def shared_strings(zip)
      entry = zip.find_entry("xl/sharedStrings.xml")
      return [] unless entry

      Nokogiri::XML(entry.get_input_stream.read).remove_namespaces!.xpath("//si").map(&:text)
    end

    def read_cell(cell, shared)
      return [ cell.at_xpath("f").text, :formula ] if cell.at_xpath("f")

      case cell["t"]
      when "inlineStr" then [ cell.at_xpath("is").text, :string ]
      when "s" then [ shared[cell.at_xpath("v").text.to_i], :string ]
      when "str" then [ cell.at_xpath("v")&.text, :string ]
      else [ cell.at_xpath("v")&.text&.then { |v| BigDecimal(v) }, :number ]
      end
    end
end

RSpec.configure do |config|
  config.include XlsxReader
end
