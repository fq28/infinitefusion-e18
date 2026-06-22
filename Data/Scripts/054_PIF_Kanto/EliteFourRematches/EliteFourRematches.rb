# The idea is for each Elite 4 members to have a pool of 12 or so Pokémon (20 for Blue, but he always has his starter) to choose from and each time you rematch them, they pick 6 out
#   of them to give some variety and unpredictabilty o the fights

# todo: Add reserve Pokemon! Maybe two extra per tier for each e4. Maybe 4 for Blue
#  todo maybe: Analyse the player's team and pick a team that counters it

# Rematch tiers:
# :1 : Unlocked after beating the league the first time (Level range same as first run (50-60) )
# :2 : Unlocked after beating Elite 4 rematch tier 1 (Level range 60-70)
# :3 : Unlocked after beating Mt. Silver  and beating Elite 4 rematch tier 2 (Level range 70-80 )
#  4: Unlocked after completing all the Gym Leader rematches and beating Elite 4 rematch tier 3 (Level range 80-90)
#  5: Unlocked after beating rematch tier 4 (Everything level 100)

E4_REMATCH_BST_RANGE = 50

class PokemonGlobalMetadata
  attr_accessor :e4RematchCache
end

def e4_randomizer_active?
  $game_switches[SWITCH_RANDOM_TRAINERS] || !$PokemonGlobal.psuedoBSTHash.nil?
end

# Cached per battle session so we don't read from disk once per Pokemon
$e4_custom_species_list_cache = nil

def e4_get_custom_list
  $e4_custom_species_list_cache ||= getCustomSpeciesList(false)
end

def e4_randomize_species_pair(head_sym, body_sym)
  use_customs = $game_switches[SWITCH_RANDOM_WILD_ONLY_CUSTOMS] && $game_switches[SWITCH_RANDOM_WILD_TO_FUSION]
  begin
    if use_customs
      custom_list = e4_get_custom_list
      ref_dex = dexNum(fusionOf(head_sym, body_sym))
      species = getNewCustomSpecies(ref_dex, custom_list, E4_REMATCH_BST_RANGE, false, false)
      return species if species && species.is_a?(Integer)
      return ref_dex
    else
      head = getNewSpecies(dexNum(head_sym), E4_REMATCH_BST_RANGE, false, Settings::NB_POKEMON, false)
      body = getNewSpecies(dexNum(body_sym), E4_REMATCH_BST_RANGE, false, Settings::NB_POKEMON, false)
      head = dexNum(head_sym) if head.nil? || head > Settings::NB_POKEMON
      body = dexNum(body_sym) if body.nil? || body > Settings::NB_POKEMON
      return [head, body]
    end
  rescue => e
    echoln "[E4Rematch] Randomization failed for #{head_sym}/#{body_sym}: #{e.message}, falling back to original"
    return [dexNum(head_sym), dexNum(body_sym)]
  end
end

def get_e4_selected_pokemon(trainer_id, rematch_tier, available_pokemon, nb_pokemon)
  if $game_switches[SWITCH_E4_REMATCH_RESET_CACHE]
    $PokemonGlobal.e4RematchCache = {}
    $e4_custom_species_list_cache = nil
    $game_switches[SWITCH_E4_REMATCH_RESET_CACHE] = false
  end
  $PokemonGlobal.e4RematchCache ||= {}
  cache_key = [trainer_id, rematch_tier]

  if $PokemonGlobal.e4RematchCache[cache_key]
    cached = $PokemonGlobal.e4RematchCache[cache_key]
    valid = cached.is_a?(Array) && !cached.empty? && cached.all? do |pkmn|
      next false unless pkmn.is_a?(Hash) && pkmn[:species]
      s = pkmn[:species]
      next true if s.is_a?(Symbol)
      next true if s.is_a?(Integer)
      next false unless s.is_a?(Array)
      s.all? { |v| v.is_a?(Symbol) || (v.is_a?(Integer) && v <= Settings::NB_POKEMON) }
    end
    return cached if valid
    $PokemonGlobal.e4RematchCache.delete(cache_key)
  end

  # Reset session cache for custom list so each new battle generation is fresh
  $e4_custom_species_list_cache = nil

  selected = select_e4_pokemon(available_pokemon, rematch_tier, nb_pokemon)

  if selected.empty?
    echoln "[E4Rematch] Warning: no Pokemon found for trainer #{trainer_id} tier #{rematch_tier}"
    selected = select_e4_pokemon(available_pokemon, 1, nb_pokemon)
  end

  if e4_randomizer_active?
    selected = selected.map do |pokemon_data|
      species_data = pokemon_data[:species]
      next pokemon_data unless species_data.is_a?(Array)
      new_data = pokemon_data.dup
      new_data[:species] = e4_randomize_species_pair(species_data[0], species_data[1])
      new_data[:randomized] = true
      new_data
    end
  end

  $PokemonGlobal.e4RematchCache[cache_key] = selected
  selected
end

def eliteFourRematch(trainer_id, trainer_name, rematch_tier, end_dialog="")
  base_line_level = 50
  base_line_level = 60 if rematch_tier == 2
  base_line_level = 70 if rematch_tier == 3
  base_line_level = 80 if rematch_tier == 4
  base_line_level = 100 if rematch_tier == 5

  available_pokemon = E4_POKEMON_POOL[trainer_id]
  nb_pokemon = rematch_tier >= 3 ? 6 : 5
  nb_pokemon = 5 if trainer_id == :CHAMPION

  selected_pokemon = get_e4_selected_pokemon(trainer_id, rematch_tier, available_pokemon, nb_pokemon)
  party = build_e4_trainer_party(selected_pokemon, base_line_level)
  party << get_rival_starter(base_line_level) if trainer_id == :CHAMPION

  items = [:FULLRESTORE, :FULLRESTORE]
  items.concat([:FULLRESTORE, :FULLRESTORE]) if rematch_tier >= 2
  items.concat([:FULLRESTORE, :FULLRESTORE]) if rematch_tier >= 4
  won = customTrainerBattle(trainer_name, trainer_id, party, 50, end_dialog, nil, nil, items)
  unlock_new_league_tiers if won && trainer_id == :CHAMPION
  return won
end


def get_rival_starter(base_line_level)
  species = pbGet(VAR_RIVAL_STARTER)
  level = base_line_level + 12
  level = 100 if level > 100
  pokemon = Pokemon.new(species, level)
  pokemon.item = :LEFTOVERS
  return pokemon
end

def build_e4_trainer_party(selected_pokemon, base_line_level)
  party = []
  selected_pokemon.each do |pokemon_data|
    begin
      party << build_e4_pokemon(pokemon_data, base_line_level)
    rescue => e
      echoln "[E4Rematch] Failed to build Pokemon #{pokemon_data[:species]}: #{e.message}"
    end
  end
  return party
end

def build_e4_pokemon(pokemon_data, base_line_level)
  level = (pokemon_data[:level] || 0) + base_line_level
  level = 100 if level > 100
  level = 1 if level < 1
  is_randomized = pokemon_data[:randomized]
  species_data = pokemon_data[:species]
  if species_data.is_a?(Array)
    species = fusionOf(species_data[0], species_data[1])
  elsif species_data.is_a?(Integer)
    result = getSpecies(species_data)
    species = result ? result.id : species_data
  else
    species = species_data
  end
  pokemon = Pokemon.new(species, level)
  pokemon.nature = pokemon_data[:nature] if pokemon_data[:nature]
  pokemon.item = pokemon_data[:item] if pokemon_data[:item]
  if !is_randomized
    pokemon.ability = pokemon_data[:ability] if pokemon_data[:ability]
    if pokemon_data[:moves]
      pokemon.moves = pokemon_data[:moves].map { |move_id| Pokemon::Move.new(move_id) }
    end
  end
  return pokemon
end

# Todo: smart select depending on the player's team
def select_e4_pokemon(all_available_pokemon, tier, number_to_select)
  available_pokemon = all_available_pokemon.select { |pkmn| pkmn[:tier] <= tier }
  return available_pokemon.sample(number_to_select)
end

def league_rematch_tiers_supported
  game_mode = getCurrentGameModeSymbol
  return true if game_mode == :CLASSIC || game_mode == :DEBUG || game_mode == :RANDOMIZED
  return false
end

def list_unlocked_league_tiers
  unlocked_tiers = []
  unlocked_tiers << 1 if $game_switches[SWITCH_LEAGUE_TIER_1]
  unlocked_tiers << 2 if $game_switches[SWITCH_LEAGUE_TIER_2]
  unlocked_tiers << 3 if $game_switches[SWITCH_LEAGUE_TIER_3]
  unlocked_tiers << 4 if $game_switches[SWITCH_LEAGUE_TIER_4]
  unlocked_tiers << 5 if $game_switches[SWITCH_LEAGUE_TIER_5]
  return unlocked_tiers
end

def select_league_tier
  return 0 unless league_rematch_tiers_supported
  available_tiers = list_unlocked_league_tiers
  return 0 if available_tiers.empty?

  available_tiers.reverse!
  commands = available_tiers.map { |tier_nb| _INTL("Tier #{tier_nb}") }
  cmd_cancel = _INTL("Cancel")
  commands << cmd_cancel
  choice = pbMessage(_INTL("Which League Rematch difficulty tier will you choose?"), commands)
  return -1 if commands[choice] == cmd_cancel
  return available_tiers[choice]
end

# Called when the player just beat the league
def unlock_new_league_tiers
  return unless league_rematch_tiers_supported

  current_tier = pbGet(VAR_LEAGUE_REMATCH_TIER)
  currently_unlocked_tiers = list_unlocked_league_tiers
  tiers_to_unlock = []
  tiers_to_unlock << 1 if current_tier == 0
  tiers_to_unlock << 2 if current_tier == 1
  tiers_to_unlock << 3 if current_tier == 2 && $game_switches[SWITCH_BEAT_MT_SILVER]
  tiers_to_unlock << 4 if current_tier == 3 && $game_variables[VAR_NB_GYM_REMATCHES] >= 16
  tiers_to_unlock << 5 if current_tier == 4
  tiers_to_unlock.each do |tier|
    next if tier == 0
    $game_switches[SWITCH_LEAGUE_TIER_1] = true if tiers_to_unlock.include?(1)
    $game_switches[SWITCH_LEAGUE_TIER_2] = true if tiers_to_unlock.include?(2)
    $game_switches[SWITCH_LEAGUE_TIER_3] = true if tiers_to_unlock.include?(3)
    $game_switches[SWITCH_LEAGUE_TIER_4] = true if tiers_to_unlock.include?(4)
    $game_switches[SWITCH_LEAGUE_TIER_5] = true if tiers_to_unlock.include?(5)
    unless currently_unlocked_tiers.include?(tier)
      pbMEPlay("Key item get")
      pbMessage(_INTL("{1} unlocked \\C[1]Tier {2} League Rematches\\C[0]!", $Trainer.name, tier))
    end
  end
  pbSet(VAR_LEAGUE_REMATCH_TIER, current_tier + 1) unless tiers_to_unlock.empty?
end

def validateE4Data
  E4_POKEMON_POOL.keys.each do |key|
    available_pokemon = E4_POKEMON_POOL[key]
    available_pokemon.each do |pokemon_data|
      build_e4_pokemon(pokemon_data, 0)
      echoln "#{pokemon_data[:species]} is valid"
    end
  end
end
