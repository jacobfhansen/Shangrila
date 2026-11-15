# Shangrila – dialogue scripts

Written scenes for the game. Characters are in [CHARACTERS.md](CHARACTERS.md), and the
conversation mechanic is described under "Conversations" in [IDEAS.md](IDEAS.md).

Notation:
- *Italics* are inner experience: the spirit's touch, and the host's own thoughts.
- `[Tag]` marks what a reply draws on (a trait, a skill, an item). See "Conversations".
- → describes what a choice leads to.

## Dawn at the shrine (the first choice)

This is the first moment the player can act (step 2 of "A game that starts by playing itself").
Until now the player has only watched the Harrow Company camp by the overgrown shrine.

### Shared setup

Grey dawn. Mist lies in the ditch along the road. Half the brambles have been hacked away
from the shrine, uncovering a weathered stone figure. Its face is worn smooth, but the
outline of a crown can still be made out.

> **Joss:** Right. Picks and crowbars. The man paid for rubble by noon, and rubble is what
> he gets.
>
> **Ithrae** *(a hand on the stone)*: Joss... it's warm. Stone shouldn't be warm at dawn.
>
> **Tikkat:** Warm stone means silver underneath. Everyone knows that.
>
> **Ommuk** *(humming a slow prayer)*: Everyone does not know that.
>
> **Maera** *(watching the trees)*: Someone's been watching this place. There are fresh tracks
> by the road.

Then the spirit touches the host for the first time. The spirit has no words yet, only
sensations (see "How the spirit communicates"). The shared opening of the inner dialogue:

> *Something stirs behind your eyes. A pressure, like a hand laid gently on the inside of your
> skull. For one heartbeat you see a hall full of light, and a crowd bowing low, to you.
> Then it is gone, and the mist is back.*

What follows depends on who the host is. The host still speaks their own line in the shared
setup, because the spirit only touches them after it.

**Playable prototype:** *Prologue* on the main menu. The in-game text is in
`Shangrila-godot/scripts/data/prologue.gd`, with short reactions written out for every reply.

---

### Joss Harrow (Brave, Greedy, Proud)

> *Joss's jaw tightens. He has had men try to get inside his head before: sergeants,
> moneylenders, a priest once. None of them got far.*
>
> *Not now,* he thinks. *Whatever you are, you're not getting a share.*
>
> *But the bowing crowd stays with him, like the taste of good wine. Nobody has bowed to Joss
> Harrow. Not ever.*

1. "You heard me. Picks out. We're paid by the stone." → The job goes on as planned. The
   others follow without question.
2. `[Proud]` "I give the orders, and I say we take a look first. Nobody touches it until I
   say so." → The group is careful. Ithrae and Ommuk approve, and Tikkat sulks.
3. "Ithrae, step away from that thing. Now." → Protective. Ithrae is startled but grateful.
   Maera notices the change in his voice.
4. `[Greedy]` "If it's worth this much to someone to smash, it's worth something whole. Let's
   think about this." → Tikkat lights up. Ommuk frowns.

### Maera Vell (Curious, Loyal, Hot-tempered)

> *Maera spins round, knife half drawn, before she understands that the touch came from
> inside.*
>
> *Who's there?* Her heart is pounding. *Show yourself, or get out of my head.*
>
> *The vision of the hall lingers. She has never seen a place like it, and she wants, badly, to
> see it again.*

1. `[Hot-tempered]` "Did someone just— no. Forget it. Let's get this done." → The job goes on.
   Maera is on edge, and she snaps at Tikkat later.
2. `[Curious]` "Did anyone else feel that? Just now?" → The others stare at her. Ithrae says
   quietly that she felt *something*. The first seed of the touch spreading.
3. `[Loyal]` "Joss, those tracks worry me. Let's finish fast and get off this road." → The job
   is done quickly. The party leaves before the watcher returns (who it was comes up later).
4. *(Say nothing. Keep watching the trees.)* → Nothing changes, for now. The spirit's hold
   on Maera grows a little quieter, and a little more patient.

### Ommuk (Pious, Calm, Generous)

> *Ommuk stops humming. For a long moment he does not move at all, which for a Thuug is
> saying something.*
>
> *So someone does listen,* he thinks, and something in his old chest goes warm. *All those
> years, praying to whoever was there. And someone was.*
>
> *Then, more slowly: But who prays to a stone with a crown on it?*

1. `[Pious]` "We should not break this. Not without a prayer first." → The group waits
   while Ommuk prays. Tikkat grumbles. Joss allows it but checks the sun.
2. `[Calm]` "Let the stone be warm. We do the job, and we do it gently." → The job goes on,
   carefully. The figure's head is set aside unbroken (it can be found again later).
3. `[Generous]` "Whatever we're paid for this, I'll give my share to the shrine's memory.
   Offerings for the next village temple." → Joss laughs at him. Ithrae doesn't.
4. "Joss, do you feel nothing? Nothing at all?" → Joss says no, too quickly. A crack in the
   leader's certainty.

### Ithrae (Curious, Melancholy, Honest) ★

The player does not know it yet, but Ithrae is an Aeldroe, and the spirit cursed her people.
Her reaction carries a dread she cannot explain.

> *The warmth of the stone floods up Ithrae's arm and into her head, and for a moment she
> cannot see her own hand.*
>
> *Then the hall of light, and the bowing crowd, and something under it all that makes her
> want to weep. Not fear. Grief. Old grief, older than she is, and it feels like it belongs to
> her.*
>
> *Why does it feel like coming home,* she thinks, *and like a wound?*

1. `[Honest]` "There's something in my head, Joss. I'm not joking. It came from the stone."
   → Shock. Joss wants to finish the job faster. Ommuk wants to pray. Tikkat backs away from
   her. The touch is out in the open from the very first scene.
2. `[Curious]` "Give me a moment with it before you break it. I need to understand this."
   → She studies the shrine and copies the worn inscription (a first clue for the journal).
3. `[Melancholy]` "It doesn't matter. Break it. Nothing that old should still be warm."
   → The job goes on. Ithrae is quiet for the rest of the day.
4. "I'm fine. It's the cold." → A lie, which is hard for her. The spirit notes that its host
   will lie for it.

### Tikkat (Greedy, Cheerful, Cowardly)

> *Tikkat's whiskers go flat against his face. Every hair on his body stands up at once.*
>
> *Nope,* he thinks. *Nope, nope, nope. Haunted stone. Haunted rat. Haunted everything.*
>
> *But the hall in the vision was full of gold, wasn't it? Floors of it. And a little voice that
> isn't quite his own suggests that a thing which shows you gold might know where more is.*

1. `[Cowardly]` "Smash it quick and let's go. Quick quick. I don't like it here." → The job is
   rushed. Tikkat keeps glancing over his shoulder all the way to Lehan.
2. `[Greedy]` "Wait, wait. What if there's something buried under it? Old shrines have
   offerings." → They dig. They find a handful of ancient coins, of a kind no one has seen
   (a first clue about Shangrila).
3. `[Cheerful]` "Haunted shrine, warm rocks, mystery tracks. Best job we've had all year!"
   → The others laugh. Relations in the party improve.
4. "Did... did anyone else just see a lot of gold?" → Blank stares. Joss tells him to lay off
   the wine. Tikkat decides to keep the next vision to himself.
