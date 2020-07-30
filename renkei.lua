--Copyright © 2015, Damien Dennehy
--All rights reserved.

--Redistribution and use in source and binary forms, with or without
--modification, are permitted provided that the following conditions are met:

--    * Redistributions of source code must retain the above copyright
--      notice, this list of conditions and the following disclaimer.
--    * Redistributions in binary form must reproduce the above copyright
--      notice, this list of conditions and the following disclaimer in the
--      documentation and/or other materials provided with the distribution.
--    * Neither the name of SpellCheck nor the
--      names of its contributors may be used to endorse or promote products
--      derived from this software without specific prior written permission.

--THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
--ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
--WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
--DISCLAIMED. IN NO EVENT SHALL DAMIEN DENNEHY BE LIABLE FOR ANY
--DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
--(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
--LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
--ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
--(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
--SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

_addon.name    = 'renkei'
_addon.author  = 'Berlioz@Asura'
_addon.version = '1.0.0'
_addon.command = 'renkei'

require('sets')
require('tables')
files = require('files')
res = require('resources')


chain_attributes = T{
    ["Liquefaction"]={elements="Fire", level=1},
    ["Impaction"]={elements="Lightning", level=1},
    ["Detonation"]={elements="Wind", level=1},
    ["Scission"]={elements="Earth", level=1},
    ["Reverberation"]={elements="Water", level=1},
    ["Induration"]={elements="Ice", level=1},
    ["Compression"]={elements="Dark", level=1},
    ["Transfixion"]={elements="Light", level=1},
    ["Fusion"]={elements="Light,Fire", level=2},
    ["Fragmentation"]={elements="Lightning,Wind", level=2},
    ["Gravitation"]={elements="Dark,Earth", level=2},
    ["Distortion"]={elements="Water,Ice", level=2},
    ["Light"]={elements="Lightning,Wind,Fire,Light", level=3},
    ["Darkness"]={elements="Water,Ice,Earth,Dark", level=3},
}
chain_combinations = T{
    -- Level 1
    ["Impaction+Liquefaction"] = "Liquefaction",
    ["Scission+Liquefaction"] = "Liquefaction",
    ["Reverberation+Impaction"] = "Impaction",
    ["Induration+Impaction"] = "Impaction",
    ["Impaction+Detonation"] = "Detonation",
    ["Compression+Detonation"] = "Detonation",
    ["Scission+Detonation"] = "Detonation",
    ["Liquefaction+Scission"] = "Scission",
    ["Detonation+Scission"] = "Scission",
    ["Transfixion+Reverberation"] = "Reverberation",
    ["Scission+Reverberation"] = "Reverberation",
    ["Reverberation+Induration"] = "Induration",
    ["Induration+Compression"] = "Compression",
    ["Transfixion+Compression"] = "Compression",
    ["Compression+Transfixion"] = "Transfixion",
    -- Level 2,
    ["Liquefaction+Impaction"] = "Fusion",
    ["Distortion+Fusion"] = "Fusion",
    ["Induration+Reverberation"] = "Fragmentation",
    ["Gravitation+Fragmentation"] = "Fragmentation",
    ["Detonation+Compression"] = "Gravitation",
    ["Fusion+Gravitation"] = "Gravitation",
    ["Transfixion+Scission"] = "Distortion",
    ["Fragmentation+Distortion"] = "Distortion",
    -- Level 3,
    ["Fusion+Fragmentation"] = "Light",
    ["Light+Light"] = "Light",
    ["Gravitation+Distortion"] = "Darkness",
    ["Darkness+Darkness"] = "Darkness"
}

available_ws = T{}
can_ignore = T{}
properties = T{}
possible_chains = T{}
possible_skillpairs = T{}
player_skills = T{}

windower.register_event("action", function(act)
    if act['category'] == 3 then
        ws_data = res.weapon_skills[act['param']]

        -- if ws_data ~= nil and not listContains(can_ignore, ws_data.id) then
        if ws_data ~= nil then
            player_name = get_player_name(act.actor_id)
            if player_name and player_skills[player_name] == nil then
                -- print('adding new player')
                player_skills[player_name] = {ws_data.id}
            elseif player_name and player_skills[player_name] ~= nil and not listContains(player_skills[player_name], ws_data.id) then
                -- print('adding new skill for existing player')
                table.insert(player_skills[player_name], ws_data.id)
            else
                -- print('skipping becuase player and skill found')
                return
            end

            print(ws_data.en)
            print(ws_data.skillchain_a)
            print(ws_data.skillchain_b)

            ws_data['actor_id'] = act.actor_id
            table.insert(available_ws, ws_data)
            -- table.insert(can_ignore, ws_data.id)

            determine_individual_chains(available_ws)
            determine_multi_chains(available_ws)
        else
            -- print("No WS Data from Resources")
            -- print(act['param'])
        end
    end
end)

-- track weaponskill usage
windower.register_event('addon command',function (command, ...)
    command = command and command:lower() or 'help'
    if command == 'help' or command == 'h' or command == '?' then
        display_help()
    elseif command == 'show' then
        local command_args = {...}
        local desired_skillchain = nil
        local limit = 7
        for i, x in pairs(command_args) do
            -- print(i, x)
            if tonumber(x) ~= nil then
                limit = tonumber(x)
            elseif tonumber(x) == nil then
                desired_skillchain = tostring(x)
            end
        end
        if desired_skillchain then
            print('found filter', desired_skillchain, limit)
            show_chains(desired_skillchain, limit)
        else
            print('no filter')
            show_chains(nil, limit)
        end
    elseif command == 'reset' then
        available_ws = T{}
        can_ignore = T{}
        properties = T{}
        possible_chains = T{}
        possible_skillpairs = T{}
        player_skills = T{}
    else
        display_help()
    end
end)

--display a basic help section
function display_help()
    windower.add_to_chat(7, _addon.name .. ' v.' .. _addon.version)
    windower.add_to_chat(7, 'Usage: //skillchainer cmd')
end

function get_player_name(id)
    mob = windower.ffxi.get_mob_by_id(id)
    if mob and mob.in_party then
        return mob.name or '???'
    else
        return nil
    end
end

function show_chains(desired_skillchain, limit)
    for k, v in pairs(table.sort(possible_skillpairs)) do
        if limit ~= nil or desired_skillchain ~= nil then
            if countSubstring(v, '->') < limit then
                -- print('limit enabled')
                if desired_skillchain ~= nil and desired_skillchain ~= 'any' then
                    -- print('filter enabled', desired_skillchain)
                    if possible_chains[v] == desired_skillchain then
                        print (v .. ' = ' .. possible_chains[v])
                    end
                else
                    -- print('no filter')
                    print (v .. ' = ' .. possible_chains[v])

                    local date = os.date('*t')

                    local file = files.new('../../logs/%s_%.4u.%.2u.%.2u.log':format('renkei', date.year, date.month, date.day))
                    if not file:exists() then
                        file:create()
                    end

                    file:append('%s\n':format(v .. ' = ' .. possible_chains[v]))
                end
            else
                -- do nothing?
            end
        else
            -- should never actually get here since the default limit will be 7
            print (v .. '->' .. possible_chains[v])
        end
    end
end

function determine_individual_chains(skill_list)
    for i, skill_a in ipairs(skill_list) do
        prop_a = skill_a.skillchain_a or ''
        prop_b = skill_a.skillchain_b or ''
        for ii, skill_b in ipairs(skill_list) do
            prop_c = skill_b.skillchain_a or ''
            prop_d = skill_b.skillchain_b or ''

            combos = T{
                prop_a .. '+' .. prop_c, -- a_c
                prop_a .. '+' .. prop_d, -- a_d
                prop_b .. '+' .. prop_c, -- b_c
                prop_b .. '+' .. prop_d, -- b_d
                -- prop_c .. '+' .. prop_a, -- c_a
                -- prop_c .. '+' .. prop_b, -- c_b
                -- prop_d .. '+' .. prop_a, -- d_a
                -- prop_d .. '+' .. prop_b -- d_b
            }
            for iii, combo in ipairs(combos) do
                if setContains(chain_combinations, combo) then
                    player_a = get_player_name(skill_a.actor_id)
                    player_b = get_player_name(skill_b.actor_id)
                    skill_pair = skill_a.en .. '(' .. player_a .. ')'  .. '->' .. skill_b.en .. '(' .. player_b .. ')'
                    inverse = skill_b.en .. '(' .. player_b .. ')' .. '->' .. skill_a.en .. '(' .. player_a .. ')'
                    if Set(possible_skillpairs)[skill_pair] or Set(possible_skillpairs)[inverse] then
                        -- do nothing
                    else
                        possible_chains[skill_pair] = chain_combinations[combo]
                        table.insert(possible_skillpairs, skill_pair)
                    end
                end
            end
        end
    end
end

function determine_multi_chains(skill_list)
    for skill_pair, effect in pairs(possible_chains) do
        for i, next_skill in ipairs(skill_list) do
            prop_a = next_skill.skillchain_a or ''
            prop_b = next_skill.skillchain_b or ''
            combos = T{
                effect .. '+' .. prop_a,
                effect .. '+' .. prop_b
            }
            for ii, combo in ipairs(combos) do
                if setContains(chain_combinations, combo) then
                    original_set = split('->', skill_pair)
                    num_skills = #original_set
                    next_skill_name = next_skill.en .. '(' .. get_player_name(next_skill.actor_id) .. ')'
                    if original_set[num_skills] == original_set[num_skills-1] and original_set[num_skills-1] == next_skill_name then
                        -- do nothing
                    elseif original_set[num_skills] == original_set[num_skills-2] and original_set[num_skills-2] == next_skill_name then
                        -- do nothing
                    elseif original_set[num_skills] == original_set[num_skills-3] and original_set[num_skills-3] == next_skill_name then
                        -- do nothing
                    else
                        multi_skill_set = skill_pair .. '->' .. next_skill_name
                        if Set(possible_skillpairs)[multi_skill_set] then
                            -- do nothing
                        else
                            possible_chains[multi_skill_set] = chain_combinations[combo]
                            table.insert(possible_skillpairs, multi_skill_set)
                        end
                    end
                end
            end
        end
    end
end

function listContains(list, value)
    for _, v in ipairs(list) do
        if value == v then
            return true
        end
    end
    return false
end

function setContains(set, key)
    if set[key] ~= nil then
        return true
    else
        return false
    end
end

function Set(list)
  local set = {}
  for _, l in ipairs(list) do set[l] = true end
  return set
end

function split(sep, s)
    local fields = {}

    local sep = sep or " "
    local pattern = string.format("([^%s]+)", sep)
    string.gsub(s, pattern, function(c) fields[#fields + 1] = c end)

    return fields
end

function countSubstring(text, sub)
    return select(2, text:gsub(sub, ""))
end
