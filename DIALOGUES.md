# Shangrila – dialogue scripts

Written scenes for the game. Characters are in [CHARACTERS.md](CHARACTERS.md), and the
conversation mechanic is described under "Conversations" in [IDEAS.md](IDEAS.md).

Notation:
- *Italics* are inner experience: the spirit's touch, and the host's own thoughts.
- `[Tag]` marks what a reply draws on (a trait, a skill, an item). See "Conversations".
- → describes what a choice leads to.

## Dawn at the shrine (the first choice)

The spirit wakes, chooses its host, and makes its first choice (steps 1–2 of "A game that
starts by playing itself").

### The waking

The screen is black. Then eyelids open, heavily, twice, and the scene comes into view: grey
dawn, the embers of a campfire, five shapes stirring around it, and the shrine.
The spirit has no host yet. Its thoughts appear in italics, with no face and no name.

> *...light.*
>
> Grey dawn. Mist lies in the ditch along the road. By the embers of a campfire, five shapes are
> stirring.
>
> **Tikkat** *(yawning)*: Who decided we sleep next to a haunted rock?
>
> **Joss:** The man paying us did. Up. All of you.
>
> *Where... am I?*
>
> **Maera** *(rolling up her blanket)*: There was a root under my back all night. The same root.
> I've named it.
>
> **Ommuk:** Roots are honest. They stay where they are. Unlike Tikkat in his sleep.
>
> **Tikkat:** I do not move in my sleep.
>
> **Ithrae:** You kicked me twice.
>
> *How long have I slept? The stone around me is old. So very old.*
>
> Half the brambles have been hacked away from the shrine, uncovering a weathered stone figure.
> Its face is worn smooth, but the outline of a crown can still be made out.
>
> *A crown. Mine?*
>
> **Joss:** Right. Picks and crowbars. The man paid for rubble by noon, and rubble is what he
> gets.
>
> *They mean to break it. Let them. There is nothing in that stone for me now.*
>
> **Ithrae** *(a hand on the stone)*: Joss... it's warm. Stone shouldn't be warm at dawn.
>
> **Tikkat:** Warm stone means silver underneath. Everyone knows that.
>
> **Ommuk** *(humming a slow prayer)*: Everyone does not know that.
>
> *Who are they? Hired hands. Five of them. Living, breathing, warm.*
>
> **Maera** *(watching the trees)*: Someone's been watching this place. There are fresh tracks
> by the road.
>
> *I am fading. The stone held me together. Without it I am smoke in the morning air.*
>
> *I must hold on to one of them. Now, before the light takes me.*

### Choosing the host

The player chooses whom the spirit holds on to, seen through the spirit's eyes:

1. **Joss Harrow:** *the one giving the orders. Hard, and hungry for something.*
2. **Maera Vell:** *the one watching the trees. Restless, sharp-eyed.*
3. **Ommuk:** *the slow one, humming a prayer to no one in particular.*
4. **Ithrae:** *the pale one with her hand on the stone. She can feel me.*
5. **Tikkat:** *the small one, all whiskers and nerves.*

### The first touch

The spirit takes hold, with a flash of light, and from here on the inner experience is seen from
inside the host:

> *Something stirs behind your eyes. A pressure, like a hand laid gently on the inside of your
> skull. For one heartbeat you see a hall full of light, and a crowd bowing low, to you.
> Then it is gone, and the mist is back.*

What follows depends on who the host is: their own reaction, then the first choice.

**In the game:** *New* on the main menu. The in-game text is in
`Shangrila-godot/scripts/data/prologue.gd`, with short reactions written out for every reply.
The mouse wheel opens the history of everything said so far (and pauses the scene).

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

## The road to Lehan

Played on the world map, in a dialogue window over it, while the party marker moves along
the road. Lines are given to preferred speakers; if the preferred one is the host, the next one
speaks instead. The in-game text is in `Shangrila-godot/scripts/data/road.gd`.

> The road to Lehan winds down through wet fields. The company walks in a loose line, tools over
> their shoulders.
>
> **Joss:** Easiest silver we've earned all year. Smash a rock, get paid.
>
> **Tikkat:** Easiest? My arms are still shaking.
>
> *The host's legs carry them along the road. Through those eyes the spirit drinks in
> everything: the fields, the sky, the faces. All of it new. None of it new.*
>
> **Ommuk:** *(Host)*, you've been quiet since the shrine.

The host's reply (the spirit now chooses it):
1. "Just tired. Bad night." → Ommuk: "Hm." He does not look convinced.
2. "Leave it." → Nobody pushes. But the sideways glances keep coming.
3. *(Look at the sky, and say nothing.)* → Tikkat: "Great. Now *(host)*'s gone strange too."

> **Maera** *(quietly)*: Has anyone noticed *(host)* hasn't blinked in a while?
>
> **Tikkat:** Don't. Don't say things like that on an empty road.
>
> Where the road dips between two thorn hedges, a bird bursts from the brush. Then it is very
> quiet.
>
> **Brigand** *(stepping out onto the road)*: That's far enough. Purses on the road, and nobody
> gets hurt. Much.
>
> **Joss:** Five of us, three of you. Bad sums, friend.
>
> **Brigand:** There's always more of us than you can see.
>
> Steel comes out on both sides.
>
> *The spirit cannot move the host's sword arm. Not yet. But it can lend a little sureness to a
> blow, or turn one aside.*

**The first fight:** three brigands. Everyone fights on their own; the spirit can guide the
host's blow or ward the host, once per round.

**Afterwards**, depending on what the spirit did:
- it warded the host → *"Did anyone else see that? The blows didn't want to touch (host).
  They just... turned."*
- it only guided blows → *"Where did (host) learn to fight like that?"*
- it did nothing → *"Lucky. We were lucky."*

### The spirit's first words: asking for control

For the first time, the spirit finds words. It asks its host to let it take control. The
player chooses the spirit's pitch; the host's known traits are shown as a hint ("The spirit
knows Tikkat: Greedy, Cheerful, Cowardly"). Each host has four pitches, and one or two of them
suit that host (✓). A wrong pitch gets pushback and another try. *(Take hold by force)* is
always there: it always works, but leaves the host afraid. The game records whether control
was given or taken (`story.consent`), for later scenes to use.

> *Do not be afraid.*

**Joss** (Brave, Greedy, Proud): *"Afraid? I've been afraid of sergeants and moneylenders. Not of
voices. Get out of my head."*
- ✓ "Follow my lead, and you will never scrape for silver again. Your debt will be the first thing
  to go." → *Go on, he thinks. I'm listening.*
- ✓ "Let me guide you, and people will bow to you, as they once bowed to me." → *They'd bow? To
  me?*
- "Your friends need you. Let me help you keep them alive." → *They're hired swords, not friends.*
- "I am old, and tired, and lost. Please." → *Beggars get nothing from me. I've been one.*

**Maera** (Curious, Loyal, Hot-tempered): *"I'm not afraid. I'm angry. Who are you?"*
- ✓ "Let me in, and I will show you the hall again, and everything behind it." → *Fine. Show me.*
- ✓ "Your friends nearly died today. Let me help you keep them safe." → *For them. Not for you.*
- "Be calm. Breathe. You are safe with me." → *Don't tell me to be calm!*
- "Coin enough for a house by the coast." → *I don't want your coin. I want answers.*

**Ommuk** (Pious, Calm, Generous): *"I have prayed for sixty years. I only wonder what took you
so long to answer."*
- ✓ "You prayed for someone to listen. I listened." → *Then I will listen too.*
- ✓ "Let me in, and together we will help those who need it." → *Help. Yes. That I can agree to.*
- "Do as I say, and you will be rich." → *What would a Thuug do with riches? Buy a bigger shell?*
- "Obey me. I was a king." → *Kings have never answered a single one of my prayers.*

**Ithrae** (Curious, Melancholy, Honest): *"I'm afraid of how familiar you feel. What are you?"*
- ✓ "I do not know what I am. Help me find out." → *That's the first honest thing anyone has said
  to me in weeks.*
- ✓ "Let me in, and I will show you what lies behind the hall of light." → *You know I can't say
  no to that.*
- "Smile. You are alive, and the day is fine." → *You're already dead. Aren't you?*
- "You will be powerful. More powerful than any mage alive." → *That word sounds wrong in your
  voice. I don't know why.*

**Tikkat** (Greedy, Cheerful, Cowardly): *"Everyone says that right before something terrible
happens. What do you want?"*
- ✓ "Let me in, and I will keep the blades away from you." → *Deal. Deal, deal, deal.*
- ✓ "Follow my lead, and your pockets will never be empty again." → *You know exactly what to say
  to a Nisk, don't you?*
- "Be brave. Face your fears." → *Brave Nisk are dead Nisk.*
- "Pray with me." → *I'll leave that to Ommuk.*

**Taken by force:** *The spirit closes around the host's will like a fist. The host fights it,
and loses. For a moment there is only terror, then a dull, sullen quiet.*

> (From now on you control the host fully in combat. The others still act on their own.)
>
> By evening the walls of Lehan rise out of the fields.

## Arrival in Lehan

Played on the Lehan town map, in a dialogue window over it, while a red dot walks the company
from the South Gate to the employer's house, and later on to the inn. Starts by itself the first
time the company enters Lehan after the road. The in-game text is in
`Shangrila-godot/scripts/data/lehan.gd`; the design is "Arrival in Lehan" in IDEAS.md.

> Inside the gate, Lehan smells of smoke, wet straw and fresh bread.
>
> **Joss:** Pay first, then beds. Our man said he'd wait for us off Tanners' Row.
>
> *The streets feel strangely familiar to the spirit, as if they were laid over older ones.*
>
> The house is narrow and plain, squeezed between a cooper's yard and a shuttered shop.
>
> A man in a plain grey coat lets them in. Nobody lives here. Somebody is only waiting here.
>
> **The Employer:** You're late. Well? Is it done?
>
> *Something cold stirs behind the host's eyes. Whoever this man is, he would see you destroyed.*

**The proof**
- *Ommuk saved the head at the shrine:* hand it over (100 silver, and Ommuk aches to see it go) or
  claim it was all smashed (60 silver; the head stays in Ommuk's pack as the Crowned Head).
- *Otherwise:* a chip of the crown, and sharp questions about the night. "Nothing happened"
  (70 silver) · "The stone was warm" (70 silver; he goes very still, and the spirit knows he is lying,
  and afraid) · *(say nothing)* (60 silver).

**Ithrae as host** can ask what the shrine was ("A nobody's. An old eyesore on a road my family
wants widened."), then give up five silver of her share for a look at his sketch, and copy the
mark in its corner: a ring, cut through by a single line.

**The pay split**: Joss, unless he is the host, takes a double share and gives Tikkat half.
- **Joss:** the player shares it: even · *[Greedy]* double for Joss (Maera soured) · *[Proud]*
  double, and Tikkat's share against his debt (Tikkat and Maera soured).
- **Tikkat:** can palm 15 silver from the purse first. The sharpest pair of eyes may notice: Joss
  wants half of it before rejoining, Ithrae is soured, the others keep quiet.
- **Ommuk:** *[Generous]* gives his share to Tikkat (Tikkat won over) · *[Pious]* gives it to
  Lehan's temple (the old priest remembers him) · *[Calm]* talks Joss down to three quarters
  for Tikkat (nobody soured) · *(say nothing)* (Tikkat soured).
- **Ithrae:** *[Honest]* calls it out in front of the employer: even shares, Tikkat grateful,
  Joss humbled and soured · *(say nothing)* (Tikkat soured).
- **Maera:** *[Loyal]* calm words: even shares, Joss grumbles · *[Hot-tempered]* angry words:
  even shares, Tikkat won over, Joss soured · *(say nothing)* (Tikkat soured). On the way out
  she spots a packed cart and boots with mud from the shrine road: he was the watcher in the
  trees, and he is leaving town.

**At the inn** everyone says goodbye in their own way (soured ones bitterly), and everyone except
the host goes to the inn's list. Until the crier in the market square has announced the mines
job, they all turn the host down ("No job, no Tikkat. Wake me when there's coin in it."). After
that, Muster starts a short talk: each wants something small that
fits their traits (Joss: his debt or his pride; Maera: the mystery or the company; Ommuk:
people in need; Ithrae: answers, or not being alone; Tikkat: a drink and a full share, or a
safe spot at the back). The wrong approach means "not yet". Soured companions want it put
right first (the coin they were short, an apology, a round for the table). Those won over just
come.

**Knocking again** at the house: "Our business is done. Go away." After the company has left
Lehan once: no reply.
