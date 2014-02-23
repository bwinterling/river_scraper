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

  def states
    ["CO", "PA", "KS", "UT", "MO"]
  end

  def collect_all_states
    states.each do |state|
      collect_beta(state)
      collect_runs(state)
      collect_rivers(state)
    end
  end

  def collect_beta(state)
    get_page("http://www.americanwhitewater.org/content/River/state-summary/state/#{state}/")
    links = page.links_with(:href => %r{/content/River/detail/id/}, :text => %r{\A\d})

    CSV.open("./beta_#{state}.csv", "wb") do |csv|
      csv << ["state","run","difficulty","gauge","range","length","gradient"]

      links.each do |link|
        link_page = link.click

        csv << [
          state,
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

  def collect_runs(state)
    get_page("http://www.americanwhitewater.org/content/River/state-summary/state/#{state}/")
    data = create_run_hash
    CSV.open("./runs_#{state}.csv", "wb") do |csv|
      csv << ["river", "run"]
      data.each { |key, value| csv << [value["river"],value["run"]] }
    end
  end

  def collect_rivers(state)
    rows = CSV.read("./runs_#{state}.csv")
    rivers = rows.map { |row| row[0] }.uniq
    CSV.open("./rivers_#{state}.csv", "wb") do |csv|
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
rr.collect_all_states
