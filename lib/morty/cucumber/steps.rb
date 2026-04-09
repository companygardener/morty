require "morty/cucumber/helpers"
require "chronic"

ParameterType(
  name:        "date",
  regexp:      /\d{4}-\d{2}-\d{2}/,
  transformer: ->(date) { date.to_date }
)

ParameterType(
  name:        "decimal",
  regexp:      /[\d.]+/,
  transformer: ->(str) { str.to_d }
)

Given /^an? (.+) accountant$/ do |type|
  @accountant = accountant_class(type).new

  unless type.to_sym == :sourceless
    @accountant.source = Data.define(:id).new(id: 1)
  end
end

Given /^the (?:accountant|configuration):$/ do |str|
  @definition = str
end

Given /^a start date of (.*)$/ do |text|
  @accountant.start_date = Chronic.parse(text).to_date
end

Given "an interest rate of {decimal}%" do |rate|
  @accountant.rates = { @accountant.start_date => rate / 100.to_d }
end

Given "a daily interest rate of {decimal}%" do |rate|
  @accountant.rates = { @accountant.start_date => rate / 100 * 365 }
end

Given "the interest rates:" do |table|
  @accountant.rates = table.rows.map { |date, rate| [date, rate.to_d / 100] }
end

Given "the schedule:" do |table|
  @accountant.schedule = activities_from(table)
end

When "I run the daily for {}" do |text|
  case text
  when "today"    then @accountant.daily Date.today
  when "tomorrow" then @accountant.daily Date.today + 1
  when /^(\d+) days? from now$/ then @accountant.daily Date.today + $1.to_i
  when /^(\d+) days?$/
    $1.to_i.times do |i|
      @accountant.daily Date.today + i
    end
  end
end

When "I simulate to/until {}" do |text|
  @accountant.simulate_to Chronic.parse(text).to_date
end

When /^I simulate (?:this activity|these activities):$/ do |table|
  schedule = activities_from(table)

  @accountant.simulate do
    schedule.each do |event|
      send *event.values_at(:type, :date, :amount)
    end
  end
end

When /^I apply (?:this activity|these activities):$/ do |table|
  activities_from(table).each do |event|
    @accountant.activity event[:type], event[:date], event[:amount]
  end
end

When "I apply a(n) {word} (activity )effective {date} for ${decimal}" do |type, date, amount|
  @accountant.activity type, @accountant.date, amount, effective_date: date
end

When "I apply a(n) {word} (activity )for ${decimal}" do |type, amount|
  @accountant.activity type, @accountant.date, amount
end

When "I save the accountant" do
  @accountant.save
end

When "I reload the accountant" do
  old = @accountant

  @schedule = old.schedule

  @accountant          = old.class.new
  @accountant.rates    = old.rates
  @accountant.source   = old.source
end

When "I save and reload the accountant" do
  date = @accountant.date

  steps %Q{
    When I save the accountant
    When I reload the accountant
    Given a start date of #{date}
  }

  @accountant.schedule = @schedule
end

When "I reload the accountant with a start date of {date}" do |date|
  steps %Q{
     When I reload the accountant
    Given a start date of #{date}
  }
end

When "I reload the accountant with a start_date of {date}" do |date|
  steps %Q{
     When I reload the accountant
    Given a start date of #{date}
  }
end

# I cancel the 1st payment on 2026-01-01
When /^I (return|cancel) the (\d)(?:st|nd|rd|th) ([^ ]+) on (\d\d\d\d-\d\d-\d\d)$/ do |return_or_cancel, ordinal, type, date|
  activities = @accountant.activities.select { |a| a.type?(type) && a.effective_date == date.to_date }
  @accountant.send(return_or_cancel.to_sym, activities[ordinal.to_i - 1])
end

When /^I (return|cancel) the (\d\d\d\d-\d\d-\d\d) ([^ ]+)$/ do |return_or_cancel, date, type|
  @accountant.send(return_or_cancel.to_sym, @accountant.activities.detect { |a| a.type?(type) && a.effective_date == date.to_date })
end

When /^I (return|cancel) the (\d\d\d\d-\d\d-\d\d) ([^ ]+) on (\d\d\d\d-\d\d-\d\d)$/ do |return_or_cancel, date, type, cancel_date|
  # @accountant.finish(cancel_date)?
  @accountant.send(return_or_cancel.to_sym, @accountant.activities.detect { |a| a.type?(type) && a.effective_date == date.to_date })
end

When "I reverse the {date} {word}" do |date, type|
  @accountant.reverse(@accountant.activities.detect { |a| a.type?(type) && a.effective_date == date })
end

Then "the {word} ledger has these balances:" do |ledger, table|
  expect(@accountant.accounts(ledger)).to include(balances_from(table))
end

Then "the {word} ledger has these aggregated balances:" do |ledger, table|
  expect(@accountant.balances(ledger)).to include(balances_from(table))
end

Then "(I have )these balances:" do |table|
  expect(@accountant.accounts).to eq(balances_from(table))
end

Then "(I have )all zero balances" do
  expect(@accountant.accounts.values.uniq).to eq([0.to_d])
end

Then "(I have )these activity counts:" do |table|
  expect(@accountant.activities.count_by_type).to eq activity_counts_from(table)
end

Then /^(?:I (?:still )?have )?(?:an?|(\d+)) (?:(\w+) )?activit(?:y|ies)$/ do |count, type|
  list = type ? @accountant.activities.with_type(type.to_sym) : @accountant.activities

  expect(list.size).to eq((count || 1).to_i)
end

Then /^the (?:accountant|configuration) is valid$/ do
  expect { eval(@definition) }.not_to raise_error
end

Then /^the (?:accountant|configuration) is invalid$/ do
  expect { eval(@definition) }.to raise_error(Morty::Error)
end

Then "I cannot save" do
  expect { @accountant.save }.to raise_error(Morty::Error, /missing source/)
end

Then "I cannot simulate" do
  expect { @accountant.simulate }.to raise_error(Morty::Error)
end

Then "I debug" do
  binding.irb
end
