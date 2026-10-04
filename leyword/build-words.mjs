import { writeFileSync, mkdirSync, readFileSync } from "node:fs";

const answers = `
about above abuse actor adapt admit adopt adult after again agent agree ahead alarm album alert
alien align alike alive along alter amber amuse angel anger angle angry apart apple apply arena
argue arise armor aroma array arrow aside asset atlas attic audio audit avoid await awake award
aware awful bacon badge baker banjo barge basic basin basis batch beach beard beast began begin
being below bench berry birth black blade blame blank blast blaze bleed blend bless blind blink
block blood bloom blown board boast bonus boost booth bound boxer brain brand brass brave bread
break breed brick bride brief bring brink broad broke brook broom brown brush build built bulge
bunch burnt burst buyer cabin cable camel candy canoe cargo carol carry carve catch cause cease
chain chair chalk champ chant charm chart chase cheap cheat check cheek cheer chest chief child
chili chill chime choir chord chore chunk cigar claim clamp clash class clean clear clerk click
cliff climb cling cloak clock close cloth cloud clown coach coast cocoa comet comic coral couch
could count court cover crack craft crane crank crash crate crave crawl crazy cream creed creek
creep crept crime crisp croak cross crowd crown crude cruel crumb crush crust curve cycle daily
dairy daisy dance death debut decay delay delta demon depth devil diary digit dirty ditch diver
dizzy dodge donor doubt dough draft drain drake drama drank drawn dread dream dress dried drift
drill drink drive drone drove drunk dryer dwarf dwell eager eagle early earth easel eaten eight
elbow elder elect elite empty enemy enjoy enter entry equal error essay ethic event every exact
exile exist extra fable faint fairy faith false fancy fatal fault favor feast fence ferry fetal
fever fiber field fiend fifth fifty fight final first fishy fixed flair flame flank flare flash
flask fleet flesh flick fling flint flirt float flock flood floor flour fluid fluke flush flute
focus foggy force forge forth forty forum found foyer frame frank fraud freak fresh frill frisk
front frost froth frown fruit fully fumes funny fuzzy gamer gauge gaunt ghost giant given giver
glade glare glass glaze gleam glide glint globe gloom glory gloss glove going grace grade grain
grand grant grape graph grasp grass grate grave gravy graze great greed green greet grief grill
grime grind gripe groan groom grope gross group grove growl grown guard guess guest guide guild
guilt habit hairy happy hardy haste hasty hatch haunt haven hazel heard heart heath heavy hedge
hefty heist hello hence heron hilly hinge hippo hitch hoard hobby honey honor horde horse hotel
hound house hover human humid humor hunch hurry husky icing ideal idiom image imply index inert
infer inlet inner input irony issue ivory jaunt jelly jewel jolly joust judge juice juicy jumbo
jumpy kayak khaki kiosk knack knave kneel knife knock known label labor laden ladle lager lance
lanky lapel lapse large laser later lathe laugh layer leafy learn lease leash least leave ledge
leech legal lemon lemur level lever light liken lilac limbo limit linen liner lingo lithe liver
livid lobby local lodge lofty logic login loose loser lousy lover lower loyal lucid lucky lunar
lunch lunge lyric madam magic magma maize major maker manga mango manor maple march marry marsh
mason match maybe mayor meant medal media medic melon mercy merge merit merry metal meter midst
might milky mimic miner minor minus mirth miser misty mixed model modem moist money month moral
moron mossy motel motor motto mound mount mourn mouse mouth movie muddy mulch mummy mural music
musty naive nanny nasal nasty naval navel needy neigh nerdy nerve never newer newly niche niece
night ninth noble noise noisy nomad north nosey novel nudge nurse nutty nylon oaken occur ocean
oddly offer often olden older olive omega onion onset opera opium orbit order organ other otter
ought ounce outer outdo owner ozone paint panel panic paper parka party pasta paste patch pause
peace peach pearl pecan pedal penal penny perch peril phase phone photo piano picky piece piggy
pilot pinch pitch pivot pixel pizza place plaid plain plane plank plant plate plaza plead pleat
pluck plump plush point poise poker polar pooch poppy porch poser pouch pound power prank prawn
press price prick pride prime print prior prism prize probe prone proof prose proud prove prowl
prune pulse punch pupil puppy purge purse quack quail quake queen query quest queue quick quiet
quill quilt quite quote rabbi radar radio rainy raise rally ranch range rapid ratio raven razor
reach react ready realm rearm rebel recap recur refer regal reign relax relay relic remit renew
repay reply rerun reset resin retry reuse revel rhyme rider ridge rifle right rigid rigor rinse
ripen risky rival river rivet roast robin robot rocky rodeo rogue roost rough round rouse route
rover rowdy royal ruddy rugby ruler rumor rural rusty sadly safer saint salad sally salon salsa
salty salute sandy satin sauce saucy sauna scale scalp scamp scant scare scarf scary scene scent
scoff scold scoop scope score scorn scour scout scowl scrap screw scrub sedan seize sense serum
serve setup seven sever shack shade shady shaft shake shaky shall shame shape share shark sharp
shave shawl shear sheen sheep sheer sheet shelf shell shift shine shiny shirk shirt shock shone
shook shoot shore short shout shove shown showy shrub shush siege sight sigma silky silly since
siren sixth sixty skate skier skill skimp skirt skull skunk slack slain slang slant slash slate
slave sleek sleep sleet slept slice slick slide slime sling slink slope slump slung slurp small
smart smash smear smell smelt smile smirk smith smoke smoky snack snail snake snare snarl sneak
sneer snide sniff snipe snore snort snout snowy snuck soapy sober soggy solar solid solve sonar
sonic sooty sorry sound south space spade spank spare spark spawn speak spear speck speed spell
spend spent spice spicy spied spike spill spilt spine spiny spire spite split spoil spoke spoof
spook spool spoon sport spout spray spree sprig spurn spurt squad squat stack staff stage staid
stain stair stake stale stalk stall stamp stand stare stark start state stave steak steal steam
steel steep steer stern stick stiff still sting stink stint stock stoic stoke stole stomp stone
stony stood stool stoop store stork storm story stout stove strap straw stray strip strut stuck
study stuff stump stung stunt style suave sugar suite sulky sunny super surge surly sushi swamp
swarm swear sweat sweep sweet swell swept swift swing swirl swoop sword swore sworn swung syrup
table taboo tacit tacky taint taken tally talon tango tangy taper tarot taste tasty taunt teach
tease teeth tempo tenet tenor tense tenth tepee tepid terra terse thank theft their theme there
these thick thief thigh thing think third thong thorn those three threw throb throw thumb thump
thyme tiara tibia tidal tiger tight tilde timer timid tipsy titan title toast today token tonal
tonic tooth topic torch torso total totem touch tough towel tower toxic toxin trace track tract
trade trail train trait tramp trash tread treat trend trial tribe trick tried tripe troll troop
trout trove truce truck truly trump trunk trust truth tulip tummy tumor tunic turbo tutor tweak
tweed twice twine twirl twist ulcer ultra uncle under undid unify union unite unity unlit unmet
untie until upper upset urban urge usage usual usher utter vague valet valid valor value valve
vapor vault vegan venom venue verge verse vicar video vigil vigor villa vinyl viola viper viral
virus visit visor vista vital vivid vixen vocal vodka vogue voice vomit voter vouch vowel wagon
waist waive waltz waste watch water waver weary weave wedge weedy weigh weird whale wharf wheat
wheel where which whiff while whine whirl whisk white whole whose widen wider widow width wield
wimpy wince winch windy wiser witch witty woken woman women woody world worry worse worst worth
would wound woven wrack wrath wreak wreck wrest wring wrist write wrong wrote wrung wryly yacht
yearn yeast yield young youth zebra zesty
`;

const extras = `
aback abase abbey abbot abhor abide abled abode abort abound abrupt abyss acorn acrid actor acute
adage adept adieu admin admit adobe adopt adore adorn adult affix afire afoot afoul after again
agape agate agent agile aging agony agree ahead aider aisle alarm album alder algae alias alibi
alien align allay alley allot allow alloy aloft alone along aloud alpha altar alter amass amaze
amber amble amend amiss among amour ample amply amuse angel anger angle angry ankle anvil aorta
apart aphid apple apply apron arbor arena argue arise armor aroma arose array arrow arson artsy
ascot ashen aside askew aspen assay asset atoll atone attar attic audio audit augur aunts aunty
avert avian avoid await awake award aware awash awful awoke axial axiom axion azure bacon badge
badly baggy baker balmy banal banjo barbs barge baron basal baste batch bathe baton bawdy bayou
beach beady beaks beams beans beard bears beast beats beech beefs beefy beeps beers beets began
beget begin begun being belch belie belly below belts bench bends berth beset betel bevel bezel
bicep biddy bidet bigot bilge bills billy binge bingo biome bipod birch births bison bitty black
blade blame bland blank blare blast blaze bleak bleat bleed bleep blend bless blimp blind bling
bling blink bliss blitz bloat block bloke blond blood bloom blown blows bluer bluff blunt blurb
blurt blush board boast bobby boded bodes bogey boggy bogus boink bolas bolus bombs bonds bones
boney bongo bonks bonus booby boost booth boots booty booze boozy borax bored borne boson bosom
bossy botch bough bound bouts bowed bowel boxer bozos brace braid brain brake brand brash brass
brave bravo brawl brawn braze bread break breed brews briar bribe brick bride brief brine bring
brink briny brisk broad broil broke brood brook broom broth brown brunt brush brute buddy budge
buggy bugle build built bulge bulky bully bunch bunny burly burnt burps burst bused buses bushy
butch butte buxom buyer bylaw cabal cabin cable cacao cache cactus cacti caddy cadet caged cagey
cakes camel cameo campy canal candy canny canoe canon caper caput carat cards cargo carol carry
carve caste catch cater catty caulk cause cavil cease cedar cello chafe chaff chain chair chalk
champ chant chaos chard charm chart chase chasm cheap cheat check cheek cheer chess chest chick
chide chief child chili chill chime china chirp chock choir choke chord chore chose chuck chump
chunk churn chute cider cigar cinch circa civic civil clack claim clamp clang clank clash clasp
class clean clear cleat cleft clerk click cliff climb cling clink cloak clock clomp clone close
cloth cloud clout clove clown clubs cluck clued clumps clung coach coast cobra cocoa colon color
comas comet comfy comic comma conch condo conic copse coral corer corny couch cough could count
coupe court coven cover covet covey cower coyly crack craft cramp crane crank crash crass crate
crave crawl craze crazy creak cream credo creed creek creep creme crepe crept cress crest crick
cried crier crime crimp crisp croak crock crone crony crook cross croup crowd crown crude cruel
crumb crump crush crust crypt cubic cumin curds curio curly curry curse curve curvy cushy cutie
cyber cycle cynic daddy daily dairy daisy dally dance dandy datum daunt dealt death debar debit
debug debut decal decay decor decoy decry defer deign deity delay delta delve demon demur denim
dense depot depth deter detox deuce devil diary dicey digit dilly dimly diner dingo dingy diode
dirge dirty disco ditch ditto ditty diver dizzy dodge dodgy dogma doing dolly donor donut dopey
doubt dough dowdy dowel downy dowry dozen draft drain drake drama drank drape drawl drawn dread
dream dress dried drier drift drill drink drive droid droll drone drool droop dross drove drown
drugs druid drunk dryer dryly duchy dully dummy dumpy dunce dusky dusty dutch duvet dwarf dwell
dwelt dying eager eagle early earth easel eaten eater ebony eclat edict edify eerie egret eight
eject eking elbow elder elect elegy elfin elide elite elope elude email embed ember emcee empty
enact endow enema enemy enjoy ennui ensue enter entry envoy epoch epoxy equal equip erase erect
erode error erupt essay ester ether ethic ethos etude evade event every evict evoke exact exalt
excel exert exile exist expel extol extra exult eying fable facet faint fairy faith false fancy
farce fatal fatty fault fauna favor feast fecal feign fella felon femme femur fence feral ferry
fetal fetch fetid fetus fever fewer fiber fibre ficus field fiend fiery fifth fifty fight filer
filet filly filmy filth final finch finer first fishy fixer fizzy flack flail flair flake flaky
flame flank flare flash flask fleck fleet flesh flick flier fling flint flirt float flock flood
floor flora floss flour flout flown fluff fluid fluke flume flung flunk flush flute flyer foamy
focal focus foggy foist folio folly foray force forge forgo forte forth forty forum found foyer
frail frame frank fraud freak freed freer fresh friar fried frill frisk fritz frock frond front
frost froth frown froze fruit fudge fugue fully fungi funky funny furor furry fussy fuzzy gaffe
gaily gamer gamma gamut gassy gaudy gauge gaunt gauze gavel gawky gayer gayly gazer gecko geeky
geese genie genre ghost ghoul giant giddy girly girth given giver glade gland glare glass glaze
gleam glean glide glint gloat globe gloom glory gloss glove glyph gnash gnome godly going golem
golfer goner goody gooey goofy goose gorge gouge gourd grace grade graft grail grain grand grant
grape graph grasp grass grate grave gravy graze great greed green greet grief grill grime grimy
grind gripe groan groin groom grope gross group grout grove growl grown gruel gruff grunt guard
guava guess guest guide guild guile guilt guise gulch gully gumbo gummy guppy gusto gusty gypsy
habit hairy halve handy happy hardy harem harpy harry harsh haste hasty hatch hater haunt haute
haven havoc hazel heady heard heart heath heave heavy hedge hefty heist helix hello hence heron
hilly hinge hippo hippy hitch hoard hobby hoist holly homer honey honor horde horny horse hotel
hotly hound house hovel hover howdy human humid humor humph humus hunch hunky hurry husky hussy
hutch hydro hyena icily icing ideal idiom idiot idler idyll igloo iliac image imbue impel imply
inane inbox incur index inept inert infer ingot inlay inlet inner input inter intro ionic irate
irony islet issue itchy ivory jaunt jazzy jelly jerky jetty jewel jiffy joint joist joker jolly
joust judge juice juicy jumbo jumpy junta juror kappa karma kayak kebab khaki kinky kiosk kitty
knack knave knead kneed kneel knelt knife knock knoll known koala krill label labor laden ladle
lager lance lanky lapel lapse large larva lasso latch later lathe latte laugh layer leach leafy
leaky leant leapt learn lease leash least leave ledge leech leery lefty legal legit lemon lemur
leper level lever libel liege light liken lilac limbo limit linen liner lingo lipid lithe liver
livid llama loamy loath lobby local locus lodge lofty logic login loose lorry loser louse lousy
lover lower lowly loyal lucid lucky lumen lumpy lunar lunch lunge lurch lurid lusty lying lymph
lyric macaw macho macro madam madly mafia magic magma maize major maker mambo mamma manga mange
mango mangy mania manly manor maple march marry marsh mason match matey mauve maxim maybe mayor
mealy meant meaty mecca medal media medic melee melon mercy merge merit merry metal meter metro
micro midge midst might milky mimic mince miner minim minor minty minus mirth miser missy mocha
modal model modem mogul moist molar moldy money month moody moose moral morph mossy motel motif
motor motto moult mound mount mourn mouse mouth mover movie mower mucky mucus muddy mulch mummy
munch mural murky mushy music musky musty myrrh nadir naive nanny nasal nasty natal naval navel
needy neigh nerdy nerve never newer newly nicer niche niece night ninja ninny ninth noble nobly
noise noisy nomad noose north nosey notch novel nudge nurse nutty nylon nymph oaken oboes occur
ocean octal octet oddly offal offer often olden older olive omega onion onset opera opine opium
optic orbit order organ other otter ought ounce outdo outer outgo ovary ovate overt ovine ovoid
owing owner oxide ozone paddy pagan paint paler palsy panel panic pansy papal paper parer parka
parry parse party pasta paste pasty patch patio patsy patty pause payee payer peace peach pearl
pecan pedal penal pence penne penny perch peril perky pesky pesto petal petty phase phone photo
piano picky piece piety piggy pilot pinch piney pinky pinto piper pique pitch pithy pivot pixel
pixie pizza place plaid plain plait plane plank plant plate plaza plead pleat plied plier pluck
plumb plume plump plunk plush poesy point poise poker polar polka polyp pooch poppy porch poser
posit posse pouch pound pouty power prank prawn preen press price prick pride pried prime primo
print prior prism privy prize probe prone prong proof prose proud prove prowl proxy prude prune
psalm pudgy puffy pulpy pulse punch pupil puppy puree purer purge purse pushy putty pygmy quack
quail quake qualm quark quart quash quasi queen queer quell query quest queue quick quiet quill
quilt quite quote quoth rabbi rabid racer radar radii radio rainy raise rajah rally ramen ranch
randy range rapid rarer raspy ratio ratty raven rayon razor reach react ready realm rearm rebel
rebus rebut recap recur recut reedy refer refit regal rehab reign relax relay relic remit renal
renew repay repel reply rerun reset resin retch retro retry reuse revel revue rhino rhyme rider
ridge rifle right rigid rigor rinse ripen riper risen riser risky rival river rivet roach roast
robin robot rocky rodeo roger rogue roomy roost rotor rouge rough round rouse route rover rowdy
rower royal ruddy ruder rugby ruler rumor rupee rural rusty sadly safer saint salad sally salon
salsa salty salve salvo sandy saner sappy sassy satin satyr sauce saucy sauna saute savor savoy
savvy scald scale scalp scaly scamp scant scare scarf scary scene scent scion scoff scold scone
scoop scope score scorn scour scout scowl scram scrap scree screw scrub scrum scuba sedan seedy
segue seize semen sense sepia serum serve servo setup seven sever sewer shack shade shady shaft
shake shaky shale shall shalt shame shank shape shard share shark sharp shave shawl shear sheen
sheep sheer sheet sheik shelf shell shied shift shine shiny shire shirk shirt shoal shock shone
shook shoot shore shorn short shout shove shown showy shrew shuck shunt shush shyly siege sieve
sight sigma silky silly since sinew singe siren sissy sixth sixty skate skier skiff skill skimp
skirt skulk skull skunk slack slain slang slant slash slate slave sleek sleep sleet slept slice
slick slide slime slimy sling slink sloop slope slosh sloth slump slung slunk slurp slush slyly
smack small smart smash smear smell smelt smile smirk smite smith smock smoke smoky smote snack
snail snake snaky snare snarl sneak sneer snide sniff snipe snoop snore snort snout snowy snuck
snuff soapy sober soggy solar solid solve sonar sonic sooth sooty sorry sound south sower space
spade spank spare spark spasm spawn speak spear speck speed spell spelt spend spent sperm spice
spicy spied spiel spike spiky spill spilt spine spiny spire spite splat split spoil spoke spoof
spook spool spoon spore sport spout spray spree sprig spunk spurn spurt squad squat squib stack
staff stage staid stain stair stake stale stalk stall stamp stand stank stare stark start stash
state stave stead steak steal steam steed steel steep steer stein stern stick stiff still stilt
sting stink stint stock stoic stoke stole stomp stone stony stood stool stoop store stork storm
story stout stove strap straw stray strip strut stuck study stuff stump stung stunk stunt style
suave sugar suing suite sulky sully sumac sunny super surer surge surly sushi swami swamp swarm
swash swath swear sweat sweep sweet swell swept swift swill swine swing swish swoon swoop sword
swore sworn swung synod syrup tabby table taboo tacit tacky taffy taint taken taker tally talon
tamer tango tangy taper tapir tardy tarot taste tasty tatty taunt tawny teach tease teddy teeth
tempo tenet tenor tense tenth tepee tepid terra terse testy thank theft their theme there these
theta thick thief thigh thing think third thong thorn those three threw throb throw thrum thumb
thump thyme tiara tibia tidal tiger tight tilde timer timid tipsy titan tithe title toast today
toddy token tonal tonic tooth topaz topic torch torso torus total totem touch tough towel tower
toxic toxin trace track tract trade trail train trait tramp trash trawl tread treat trend triad
trial tribe trice trick tried tripe trite troll troop trope trout trove truce truck truer truly
trump trunk truss trust truth tryst tuber tulip tummy tumor tunic turbo tutor twang tweak tweed
tweet twice twine twirl twist twixt tying udder ulcer ultra umbra uncle uncut under undid undue
unfed unfit unify union unite unity unlit unmet unset untie until unwed unzip upper upset urban
urine usage usher using usual usurp utile utter vague valet valid valor value valve vapor vault
vaunt vegan venom venue verge verse verso vicar video vigil vigor villa vinyl viola viper viral
virus visit visor vista vital vivid vixen vocal vodka vogue voice voila vomit voter vouch vowel
vying wacky wafer wager wagon waist waive waltz warty waste watch water waver waxen weary weave
wedge weedy weigh weird welch welsh wench whack whale wharf wheat wheel whelp where which whiff
while whine whiny whirl whisk white whole whoop whose widen wider widow width wield wight willy
wimpy wince winch windy wiser wispy witch witty woken woman women woody wooer wooly woozy wordy
world worry worse worst worth would wound woven wrack wrath wreak wreck wrest wring wrist write
wrong wrote wrung wryly yacht yearn yeast yield young youth zebra zesty zonal
`;

const banned = new Set(
  "fecal fetish fetus hymen penis pubic semen urine whore slut cunt cunts nigga kikes chink gooks spics spick dykes fagot coons faggy".split(" "),
);

function take(raw) {
  const seen = new Set();
  const out = [];
  const bad = [];
  for (const word of raw.trim().split(/\s+/)) {
    if (!/^[a-z]{5}$/.test(word) || banned.has(word) || seen.has(word)) {
      if (word) bad.push(word);
      continue;
    }
    seen.add(word);
    out.push(word);
  }
  out.sort();
  return { out, bad };
}

const answerSet = take(answers);
const extraSet = take(extras);
const dictionary = take(readFileSync(new URL("./extra-words.txt", import.meta.url), "utf8"));
const guessSet = new Set([...answerSet.out, ...extraSet.out, ...dictionary.out]);
const guesses = [...guessSet].sort();

if (answerSet.bad.length) {
  console.log("dropped from answers:", [...new Set(answerSet.bad)].join(" "));
}

const lua = `-- Generated. This order is the puzzle order. Do not sort it again.
Leyword = Leyword or {}
Leyword.Answers = {
${answerSet.out.map((w) => `  "${w}",`).join("\n")}
}

local guesses = {
${guesses.map((w) => `  "${w}",`).join("\n")}
}

Leyword.GuessSet = {}
for i = 1, #guesses do
  Leyword.GuessSet[guesses[i]] = true
end
`;

const ts = `// Generated. Puzzle order matches the WoW Forever addon. Do not sort it again.
export const answers: string[] = [
${answerSet.out.map((w) => `  "${w}",`).join("\n")}
];

export const guessList: string[] = [
${guesses.map((w) => `  "${w}",`).join("\n")}
];
`;

mkdirSync("/workspace/leyword/Leyword", { recursive: true });
mkdirSync("/workspace/src/lib", { recursive: true });
writeFileSync("/workspace/leyword/Leyword/Words.lua", lua);
writeFileSync("/workspace/src/lib/words.ts", ts);
console.log(`answers ${answerSet.out.length} guesses ${guesses.length}`);
