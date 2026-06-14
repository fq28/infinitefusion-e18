class Pokemon
  def battle_stat(key)
    return (@battle_stats || {})[key] || 0
  end

  def increment_battle_stat(key, amount = 1)
    @battle_stats ||= {}
    @battle_stats[key] = (@battle_stats[key] || 0) + amount
  rescue
  end

  def killed_by_data
    return (@battle_stats || {})[:killed_by]
  rescue
    return nil
  end

  def record_killed_by(trainer: nil, pokemon: nil, move: nil, species: nil)
    @battle_stats ||= {}
    @battle_stats[:killed_by] = {
      trainer: trainer,
      pokemon: pokemon,
      move:    move,
      species: species
    }
  rescue
  end
end
