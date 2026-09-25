-- Timed objective events per pro match, with the side each one belongs to resolved.
-- OpenDota's encodings, checked against the data:
--   CHAT_MESSAGE_FIRSTBLOOD: player_slot is the killer, key the victim's slot (0-9);
--     they are always on opposite sides.
--   building_kill: key is the building that fell (npc_dota_goodguys_* = Radiant's,
--     npc_dota_badguys_* = Dire's); the killer may be a creep, or the owner on a deny.
--   CHAT_MESSAGE_ROSHAN_KILL: team 2 = Radiant, 3 = Dire.
--   CHAT_MESSAGE_AEGIS / _AEGIS_STOLEN: player_slot is who picked the Aegis up; a
--     stolen Aegis is picked up by the side that did not kill Roshan.
-- time is game seconds from the horn; negative before it.
select
    m.match_id,
    o._dlt_list_idx as event_order,
    o.type as event_type,
    o.time as time_s,
    o.key as event_key,
    o.player_slot,
    case
        when o.type = 'building_kill' then
            case
                when o.key like 'npc_dota_goodguys_%' then 'radiant'
                when o.key like 'npc_dota_badguys_%' then 'dire'
            end
    end as building_side,
    case
        when o.type = 'building_kill' then
            case
                when o.key like '%tower%' then 'tower'
                when o.key like '%rax%' then 'barracks'
                when o.key like '%fort%' then 'ancient'
            end
    end as building_type,
    case
        when o.type = 'CHAT_MESSAGE_ROSHAN_KILL' then
            case o.team when 2 then 'radiant' when 3 then 'dire' end
        when o.type in ('CHAT_MESSAGE_FIRSTBLOOD', 'CHAT_MESSAGE_AEGIS', 'CHAT_MESSAGE_AEGIS_STOLEN') then
            case when o.player_slot < 128 then 'radiant' when o.player_slot >= 128 then 'dire' end
    end as actor_side
from {{ source('raw', 'match_details__objectives') }} as o
inner join {{ source('raw', 'match_details') }} as m on m._dlt_id = o._dlt_parent_id
