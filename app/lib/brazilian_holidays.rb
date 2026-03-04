module BrazilianHolidays
  # Fixed national holidays: [month, day]
  FIXED = [
    [ 1,  1 ],  # Confraternização Universal
    [ 4,  21 ], # Tiradentes
    [ 5,  1 ],  # Dia do Trabalho
    [ 9,  7 ],  # Independência do Brasil
    [ 10, 12 ], # Nossa Senhora Aparecida
    [ 11, 2 ],  # Finados
    [ 11, 15 ], # Proclamação da República
    [ 12, 25 ]  # Natal
  ].freeze

  def self.holiday?(date)
    date = date.to_date
    return true if FIXED.any? { |m, d| date.month == m && date.day == d }
    # Consciência Negra became a national holiday in 2024 (Lei nº 14.759/2023)
    return true if date.year >= 2024 && date.month == 11 && date.day == 20
    moveable_holidays(date.year).include?(date)
  end

  def self.business_day?(date)
    date = date.to_date
    !date.on_weekend? && !holiday?(date)
  end

  private_class_method def self.moveable_holidays(year)
    easter = easter_date(year)
    [
      easter - 48, # Segunda-feira de Carnaval
      easter - 47, # Terça-feira de Carnaval
      easter - 2,  # Sexta-feira Santa
      easter + 60  # Corpus Christi
    ]
  end

  # Anonymous Gregorian algorithm
  private_class_method def self.easter_date(year)
    a = year % 19
    b = year / 100
    c = year % 100
    d = b / 4
    e = b % 4
    f = (b + 8) / 25
    g = (b - f + 1) / 3
    h = (19 * a + b - d - g + 15) % 30
    i = c / 4
    k = c % 4
    l = (32 + 2 * e + 2 * i - h - k) % 7
    m = (a + 11 * h + 22 * l) / 451
    month = (h + l - 7 * m + 114) / 31
    day   = ((h + l - 7 * m + 114) % 31) + 1
    Date.new(year, month, day)
  end
end
