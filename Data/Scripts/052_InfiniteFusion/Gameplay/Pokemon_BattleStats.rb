class Pokemon
  def battle_stat(key)
    return (@battle_stats || {})[key] || 0
  end

  def increment_battle_stat(key, amount = 1)
    @battle_stats ||= {}
    @battle_stats[key] = (@battle_stats[key] || 0) + amount
  end
end
