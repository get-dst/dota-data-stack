---
metric: public_sample
summary: The public-match numbers come from a sample, the newest games OpenDota listed at each load, not from every game played.
aliases: [pubs, public matches, matchmaking, ranked games, pub games]
---

Dota 2 has far more public games than one free API budget can list, so the loader takes the
newest few thousand each time it runs and keeps every one it has seen. That is a sample,
biased toward the hours the loader ran and the regions active then. It is fine for
comparing heroes and brackets within the sample; it is not a count of games played. Every
answer over pub data carries that scope.
