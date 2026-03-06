require "test_helper"

class BrazilianHolidaysTest < ActiveSupport::TestCase
  # Fixed national holidays
  test "January 1 is a holiday" do
    assert BrazilianHolidays.holiday?(Date.new(2026, 1, 1))
  end

  test "April 21 is a holiday" do
    assert BrazilianHolidays.holiday?(Date.new(2026, 4, 21))
  end

  test "May 1 is a holiday" do
    assert BrazilianHolidays.holiday?(Date.new(2026, 5, 1))
  end

  test "September 7 is a holiday" do
    assert BrazilianHolidays.holiday?(Date.new(2026, 9, 7))
  end

  test "October 12 is a holiday" do
    assert BrazilianHolidays.holiday?(Date.new(2026, 10, 12))
  end

  test "November 2 is a holiday" do
    assert BrazilianHolidays.holiday?(Date.new(2026, 11, 2))
  end

  test "November 15 is a holiday" do
    assert BrazilianHolidays.holiday?(Date.new(2026, 11, 15))
  end

  test "December 25 is a holiday" do
    assert BrazilianHolidays.holiday?(Date.new(2026, 12, 25))
  end

  # Consciência Negra (post-2024)
  test "November 20 is a holiday from 2024 onward" do
    assert BrazilianHolidays.holiday?(Date.new(2024, 11, 20))
    assert BrazilianHolidays.holiday?(Date.new(2026, 11, 20))
  end

  test "November 20 is not a holiday before 2024" do
    assert_not BrazilianHolidays.holiday?(Date.new(2023, 11, 20))
  end

  # Moveable holidays based on Easter 2025 (April 20)
  test "Good Friday 2025 is a holiday" do
    assert BrazilianHolidays.holiday?(Date.new(2025, 4, 18))
  end

  test "Carnival Monday 2025 is a holiday" do
    assert BrazilianHolidays.holiday?(Date.new(2025, 3, 3))
  end

  test "Carnival Tuesday 2025 is a holiday" do
    assert BrazilianHolidays.holiday?(Date.new(2025, 3, 4))
  end

  test "Corpus Christi 2025 is a holiday" do
    assert BrazilianHolidays.holiday?(Date.new(2025, 6, 19))
  end

  # Regular weekday is not a holiday
  test "regular weekday is not a holiday" do
    assert_not BrazilianHolidays.holiday?(Date.new(2026, 3, 4))
  end

  # business_day?
  test "a regular weekday that is not a holiday is a business day" do
    assert BrazilianHolidays.business_day?(Date.new(2026, 3, 4))
  end

  test "Saturday is not a business day" do
    assert_not BrazilianHolidays.business_day?(Date.new(2026, 3, 7))
  end

  test "Sunday is not a business day" do
    assert_not BrazilianHolidays.business_day?(Date.new(2026, 3, 8))
  end

  test "a national holiday is not a business day" do
    assert_not BrazilianHolidays.business_day?(Date.new(2026, 12, 25))
  end

  test "accepts DateTime and converts to date" do
    assert BrazilianHolidays.holiday?(DateTime.new(2026, 12, 25, 10, 0, 0))
  end
end
