# =============================================================================
# The Fallen - Graveyard Gauntlet
# Rebuilds your dead teammates as a single ghostly trainer battle.
# To trigger: pause menu → "The Fallen"
# =============================================================================

# -----------------------------------------------------------------------------
# Builds one fallen Pokemon with exact EVs, IVs, ability, nature, item, moves.
# Unspecified IVs default to 31. Returns nil silently on any error.
# -----------------------------------------------------------------------------
def build_fallen_pokemon(species_sym, level, nickname, item, ability, nature, evs, ivs, moves)
  begin
    pkmn          = Pokemon.new(species_sym, level)
    pkmn.name     = nickname
    pkmn.item     = item
    pkmn.ability  = ability
    pkmn.nature   = nature

    GameData::Stat.each_main do |s|
      pkmn.ev[s.id] = evs[s.id] || 0
    end
    GameData::Stat.each_main do |s|
      pkmn.iv[s.id] = ivs.key?(s.id) ? ivs[s.id] : 31
    end

    pkmn.calc_stats
    pkmn.moves = moves.map { |m| Pokemon::Move.new(m) }
    pkmn.instance_variable_set(:@is_fallen_ghost, true)
    return pkmn
  rescue => e
    echoln "GraveyardGauntlet: failed to build #{species_sym}: #{e}"
    return nil
  end
end

# -----------------------------------------------------------------------------
# The team. fusionOf(HEAD, BODY) — base Pokemon in parentheses = HEAD (first arg),
# "Fusion: X" in the export = BODY (second arg).
# -----------------------------------------------------------------------------
def build_the_fallen_team
  team = []

  # Dramagwin — Rhydon (head) / Torkoal (body)
  team << build_fallen_pokemon(
    fusionOf(:RHYDON, :TORKOAL), 73, "Dramagwin",
    :EVIOLITE, :DROUGHT, :ADAMANT,
    { HP: 152, DEFENSE: 106, SPECIAL_DEFENSE: 252 },
    {},
    [:STOMPINGTANTRUM, :ROCKSLIDE, :PROTECT, :FIREPUNCH]
  )

  # Wellcilius — Venusaur (head) / Chandelure (body)
  team << build_fallen_pokemon(
    fusionOf(:VENUSAUR, :CHANDELURE), 73, "Wellcilius",
    :ASSAULTVEST, :CHLOROPHYLL, :MODEST,
    { HP: 252, DEFENSE: 6, SPECIAL_ATTACK: 252 },
    { ATTACK: 9, DEFENSE: 19, SPECIAL_DEFENSE: 20 },
    [:HEATWAVE, :SHADOWBALL, :GIGADRAIN, :PSYCHIC]
  )

  # Purpruu — Charizard (head) / Meganium (body)
  team << build_fallen_pokemon(
    fusionOf(:CHARIZARD, :MEGANIUM), 73, "Purpruu",
    :LIFEORB, :SOLARPOWER, :MODEST,
    { HP: 6, SPECIAL_ATTACK: 252, SPEED: 252 },
    { ATTACK: 1, SPECIAL_ATTACK: 24, SPECIAL_DEFENSE: 0 },
    [:HEATWAVE, :FOCUSBLAST, :SOLARBEAM, :ANCIENTPOWER]
  )


  # Krakom — Porygon2 (head) / Wigglytuff (body)
  team << build_fallen_pokemon(
    fusionOf(:PORYGON2, :WIGGLYTUFF), 73, "Krakom",
    :LEFTOVERS, :TRACE, :BOLD,
    { HP: 252, DEFENSE: 86, SPECIAL_ATTACK: 172 },
    { HP: 30, ATTACK: 0, SPECIAL_DEFENSE: 26, SPEED: 14 },
    [:MOONBLAST, :ROLEPLAY, :ALLYSWITCH, :ICEBEAM]
  )



  # TheNewKiwikelly — Alakazam (head) / Arbok (body)
  team << build_fallen_pokemon(
    fusionOf(:ALAKAZAM, :ARBOK), 73, "TheNewKiwikelly",
    :BRIGHTPOWDER, :INTIMIDATE, :TIMID,
    { SPECIAL_ATTACK: 173, SPECIAL_DEFENSE: 152, SPEED: 185 },
    { DEFENSE: 6, SPECIAL_DEFENSE: 26, SPEED: 30 },
    [:PSYCHIC, :SKILLSWAP, :KNOCKOFF, :ENCORE]
  )

  # Aeres — Cresselia (head) / Klefki (body)
  team << build_fallen_pokemon(
    fusionOf(:CRESSELIA, :KLEFKI), 73, "Aeres",
    :LIGHTCLAY, :PRANKSTER, :MODEST,
    { HP: 252, SPECIAL_ATTACK: 252, SPECIAL_DEFENSE: 6 },
    { ATTACK: 0, SPECIAL_ATTACK: 18, SPEED: 25 },
    [:REFLECT, :LIGHTSCREEN, :MOONLIGHT, :MOONBLAST]
  )

  return team.compact
end

# -----------------------------------------------------------------------------
# Entry point. Called from pause menu → "The Fallen".
# -----------------------------------------------------------------------------
def startGraveyardGauntlet
  team = build_the_fallen_team
  if team.empty?
    pbMessage(_INTL("(The fallen didn't load. Check the error log.)"))
    return
  end

  pbMessage(_INTL("..."))
  pbMessage(_INTL("Something stirs in the shadows."))
  pbMessage(_INTL("Familiar faces... but wrong. Hollow."))
  pbMessage(_INTL("HansWarris want to battle!"))

  $PokemonGlobal.nextBattleBGM  = "Face"
  $PokemonGlobal.nextBattleBack = "tower"

  customTrainerBattle(
    "HansWarris",
    :CHAMPION,
    team,
    77,
    "...you may rest now.",
    "Graphics/Trainers/ho-oh",
    nil,
    [:FULLRESTORE, :FULLRESTORE, :FULLRESTORE]
  )
end
