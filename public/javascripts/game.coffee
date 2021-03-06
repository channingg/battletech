
d6 = ->
  return Math.floor Math.random() * 6 + 1

d12 = ->
  return Math.floor Math.random() * 12 + 1


window.players = (JSON.parse localStorage.getItem 'players') or []



add_critical_message = (message)->
  if critical_message
    critical_message += "<br>"
  critical_message += message


# Damage handlers
critical_hit = (part)->

  add_critical_message 'critical!'
  console.log 'critical on ',part,'!!!'

  # Get the sparse list of mech parts and compact it into a space to select from.
  candidates = []
  i = 1
  while i <= 12
    slot = active_mech['CRIT_'+part+'_'+i]
    if slot and not active_mech['destroyed_'+part+'_'+i]
      candidates.push
        row: i
        slot: slot
    i += 1
  
  # 
  if candidates.length
    # Select a part to
    hit = candidates[Math.floor(Math.random()*candidates.length)]
    add_critical_message 'hit '+part+' : '+hit.slot
    console.log 'destroyed',hit.slot
    active_mech['destroyed_'+part+'_'+hit.i] = true

  #else if PARTS[part].damage_flows_to
  #  critical_hit PARTS[part].damage_flows_to


destroy = ->
  active_mech.destroyed = true
  alert "DESTROYED!!!"


_da_phase = {}
damage_animation = ($part, damage, critical = '')->
  loc = $part.offset()
  $('body').append $damage = $("<div class='damage-alert'><div class='num'>" + damage + "</div><div class='crit'>" + critical + "</div></div!>")
  part = $part.get(0).className
  _da_phase[part] ?= 0
  _da_phase[part] += 2
  $damage.css
    left: loc.left + Math.sin(_da_phase[part]) * 15
    top: loc.top + Math.cos(_da_phase[part]) * 15
  setTimeout ->
    $damage.remove()
  ,3000

roll_for_criticals = (part)->
  roll = d6() + d6()
  
  console.log 'critical roll',roll

  if roll >= 8 and roll <= 9
    critical_hit part
  
  if roll >= 10 and roll <= 11
    critical_hit part
    critical_hit part
  
  if roll is 12
    if part is "HEAD"
      return destroy()
    else if part.indexOf("ARM") > -1 or part.indexOf('LEG') > -1
      add_critical_message part + ' blown off!'
      structure = 0
    else
      critical_hit part
      critical_hit part
      critical_hit part


critical_message = ''
damage_to = (part, damage)->
  
  original_part = part

  console.log part, 'hit with', damage, 'damage!'
  $part = $('.'+part)
  critical_message = ''
  #armor = parseInt $part.find('.armor').val()
  #structure = parseInt $part.find('.structure').val()
  orig_armor = armor = active_mech['armor_'+part]
  orig_structure = structure = active_mech['structure_'+part]

  # Damage first deducted from armor.
  armor -= damage
  if armor < 0 # an remaining damage passed to structure

    # REAR TORSO ARMOR MAPS TO FRONT TORSO STRUCTURE
    part = part.replace '_REAR', ''
    $part = $('.'+part)
    structure = active_mech['structure_'+part]

    # Remainder comes off structure.
    if structure # If there's any structure left, administer a critical.
      roll_for_criticals part

    structure += armor
    console.log 'hit structure down to', structure
    armor = 0

    if structure < 1

      damage_flows_to = PARTS[part].damage_flows_to
      if original_part.indexOf("ARM") or original_part.indexOf("LEG")
        if original_part.indexOf("_REAR") > -1
          damage_flows_to += "_REAR"

      if damage_flows_to is "DEATH"
        destroy()
      else
        if structure < 0
          if orig_structure > 0
            console.log part, 'blown off!'
          console.log -structure, 'damaged flows to', damage_flows_to
          damage_to damage_flows_to, -structure
          # blow off other parts too.
          active_mech['structure_'+PARTS[part].destroy_applies_to] = 0
          active_mech['armor_'+PARTS[part].destroy_applies_to] = 0
        structure = 0
  
  # update structure and armor if it changed
  # and show the damage animation
  if orig_structure isnt structure or orig_armor isnt armor
    damage_animation $part, damage, critical_message
    active_mech['structure_'+part] = structure
    active_mech['armor_'+original_part] = armor

window.hit_with_weapon = (weapon)->
  console.log "HIT WITH",weapon.name
  side = $.trim $('.sides .active').text()
  console.log "SIDE", side

  apply_damage = (dmg)->
    if weapon.name is 'Punch' or weapon.name is "Hatchet"
      roll = d6()
      location = PUNCH_HIT_LOCATION[side][roll + '']
    else if weapon.name is 'Kick'
      roll = d6()
      location = KICK_HIT_LOCATION[side][roll + '']
    else
      roll = d6() + d6()
      location = RANGED_HIT_LOCATION[side][roll + '']

    console.log 'hit the', location, 'for',dmg
    damage_to location, dmg

    if roll is 2
      roll_for_criticals location

  m = weapon.name.match /(\S+)\s(\d+)/
  if m
    # Missile fired.
    qty = m[2]
    missile_type = m[1]
    roll = d6() + d6()
    qty = MISSILE_HITS_TABLE[roll][MISSILE_HITS_COLUMNS[qty]]
  else
    qty = 1
    missile_type = null
  
  if missile_type
    console.log 'number of hits', qty, 'of type', missile_type

  if missile_type is 'SRM'
    idx = qty
    while idx
      apply_damage 2
      idx -= 1

  else if missile_type is 'LRM'
    idx = qty
    while idx > 0
      apply_damage Math.min(5, idx)
      idx -= 5

  else
    apply_damage weapon.damage



