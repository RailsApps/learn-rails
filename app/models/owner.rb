class Owner

  def name
    name = 'Foobar Kadigan'
  end

  def birthdate
    birthdate = Date.new(1990, 9, 22)
  end

  def countdown
    today = DateTime.now
    birthday = Date.new(today.year, self.birthdate.month, self.birthdate.day)
    countdown = (birthday - today).to_i
  end

end
