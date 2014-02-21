require 'rubygems'
require 'mechanize'
require 'pry'
require 'csv'

class RiverRuns

  attr_reader :agent, :page

  def initialize
    @agent = Mechanize.new
  end

  def get_page(url)
    @page = agent.get(url)
  end

  def collect_beta
    get_page("http://www.americanwhitewater.org/content/River/state-summary/state/CO/")
    links = page.links_with(:href => %r{/content/River/detail/id/}, :text => %r{\A\d})

    CSV.open("./beta.csv", "wb") do |csv|
      csv << ["run","difficulty","gauge","range","length","gradient"]

      links.each do |link|
        link_page = link.click

        csv << [
          link_page.search("h2")[1].children.text, #run_name
          link_page.search(".row-1").search("td")[0].children.text, #difficulty
          find_gauge(link_page),
          find_range(link_page),
          link_page.search(".row-2").search("td").children.text.strip, #length
          link_page.search(".row-3").search("td").children.text.strip #gradient
        ]

      end
    end
  end

  def find_range(link_page)
    begin
      link_page.search(".row-1").search("td")[2].children.text.strip
    rescue Exception
      return ""
    end
  end


  def find_gauge(link_page)
    begin
      link_page.search(".row-1").search("td")[1].children.text.strip
    rescue Exception
      return ""
    end
  end

  def collect_runs
    get_page("http://www.americanwhitewater.org/content/River/state-summary/state/PA/")
    data = create_run_hash
    CSV.open("./runs.csv", "wb") do |csv|
      csv << ["river", "run"]
      data.each { |key, value| csv << [value["river"],value["run"]] }
    end
  end

  def collect_rivers
    rows = CSV.read("./runs.csv")
    rivers = rows.map { |row| row[0] }.uniq
    CSV.open("./rivers.csv", "wb") do |csv|
      rivers.each { |river| csv << [river] }
    end
  end

  def create_run_hash
    data = {}
    page.links.each do |link|
      if link.href.include?("/content/River/detail/id")
        if data[link.href]
          if link.dom_class == 'rivername'
            data[link.href]["river"] = link.text.strip
          else
            data[link.href]["run"] = link.text
          end
        else
          data[link.href] = {}
          if link.text.scan(/\A\d/).empty?
            data[link.href]["river"] = link.text.strip
          else
            data[link.href]["run"] = link.text
          end
        end
      end
    end
    data
  end

end
rr = RiverRuns.new
rr.collect_beta
rr.collect_runs
rr.collect_rivers
