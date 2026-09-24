---
metric: bracket
summary: The rank bracket of a public match, from the average rank tier of its ten players.
aliases: [rank bracket, skill bracket, medal, rank tier, Herald, Guardian, Crusader, Archon, Legend, Ancient, Divine, Immortal]
sql: brackets.bracket_name
---

Herald, Guardian, Crusader, Archon, Legend, Ancient, Divine, Immortal, in that order.
A match's bracket is the average of its players' rank tiers, so a Legend match can hold an
Archon and an Ancient. Immortal games are rare in the public feed, so that bracket is often
absent from the sample; say so rather than reporting a zero. Pro matches have no bracket; the pros play in leagues, not in ranked
matchmaking.
