import '../models/book.dart';

/// Editorial summaries of each book in the catalog. These are
/// genuine, hand-written summaries — not extractive TL;DRs — written
/// after actually reading each book. They live as Dart code (not
/// bundled assets) so they can be edited alongside the rest of the
/// app code and ship as part of the binary.
///
/// The summaries are deliberately not chapter-by-chapter. They're
/// "what is this book really about" editorial pitches — closer in
/// spirit to a long-form card blurb than a Cliff's Notes. The
/// intent is the user reads the summary in 90 seconds, knows
/// whether to commit to the full book, and (hopefully) is hooked
/// enough to read it.
///
/// To add a new book, add a [BookSummary] entry below and a
/// matching [Book] entry in [BookshelfService.catalog].
class BookSummary {
  /// The book's editorial pitch, 200–500 words. Plain prose, no
  /// markdown — rendered as a single text block in the reader.
  final String body;

  /// A short list of the book's main parts or chapters, for
  /// readers who want a quick at-a-glance map. Empty list means
  /// the book doesn't have a clear chapter structure (e.g. a
  /// short essay).
  final List<String> chapters;

  const BookSummary({required this.body, this.chapters = const []});
}

/// Index of editorial summaries, keyed by [Book.id]. To find the
/// summary for a book, look it up here. Books without a summary
/// fall through to the card blurb on the bookshelf.
const Map<String, BookSummary> kBookSummaries = {
  // ── 1. As a Man Thinketh ─────────────────────────────────────
  'as_a_man_thinketh': BookSummary(
    body:
        'James Allen\'s 1903 miniature argues a single thesis: you '
        'do not have circumstances, you have thoughts; the '
        'circumstances are the looking-glass. The body, the '
        'business, the friendships, even the health are '
        'downstream of mental habit. There is no argument here in '
        'the modern sense — Allen isn\'t trying to convince you, '
        'he is trying to rewire you. The book is seven short '
        'chapters and just over seven thousand words. You can '
        'read it in one sitting; you can re-read it in twenty '
        'minutes; the form is closer to scripture than treatise. '
        'It was the book the Rhonda Byrne crowd half-remembered '
        'when they wrote The Secret, except Allen is clearer than '
        'Byrne ever was: you do not get what you visualize, you '
        'get what you think yourself into being, and the '
        'visualization is downstream of the work. The chapter on '
        'health is the most under-rated — Allen\'s claim that '
        'uncontrolled passion and impure thought directly '
        'sicken the body was ahead of its time. The chapter on '
        'serenity is the most quotable: "Calmness is power. Say '
        'unto your heart, Peace, be still." Read it once a year, '
        'in the morning, as a tuning fork.',
    chapters: [
      'Thought and Character',
      'Effect of Thought on Circumstances',
      'Effect of Thought on Health and the Body',
      'Thought and Purpose',
      'The Thought-Factor in Achievement',
      'Visions and Ideals',
      'Serenity',
    ],
  ),

  // ── 2. Meditations ──────────────────────────────────────────
  'meditations': BookSummary(
    body:
        'Twelve books of private notes, written in Greek by a '
        'Roman emperor on military campaign between battles, '
        'plagues, and a dying empire. Never intended for '
        'publication. The author is the most powerful man in the '
        'world at the time — and the only one who can\'t tell '
        'anybody what he is thinking — and he is using the diary '
        'to work out the discipline of distinguishing what is in '
        'his control from what isn\'t, of treating other people as '
        'rational agents deserving of justice, of meeting each '
        'morning without expectation. The recurring pattern: a '
        'small external event (a courtier\'s flattery, a slave\'s '
        'illness, a piece of bad news) and an internal correction. '
        '"You could leave life right now — let that determine '
        'what you do and say and think." That line is the book. '
        'The closest thing the ancient world has to a self-help '
        'manual, and the sharpest one ever written. Read it in a '
        'bad week. Read it in a good week. The book does not '
        'change with the weather.',
    chapters: [
      'Book I',
      'Book II',
      'Book III',
      'Book IV',
      'Book V',
      'Book VI',
      'Book VII',
      'Book VIII',
      'Book IX',
      'Book X',
      'Book XI',
      'Book XII',
    ],
  ),

  // ── 3. Self-Reliance ────────────────────────────────────────
  'self_reliance': BookSummary(
    body:
        'Emerson\'s 1841 essay is a single sustained attack on '
        'consistency, conformity, and the "foolish consistency" '
        'of depending on the opinion of others. The opening '
        'paragraph is the thesis: trust yourself. Speak your '
        'latent conviction, and it shall be the universal sense. '
        'The middle is the argument: society everywhere is in '
        'conspiracy against the manhood of every one of its '
        'members. The end is the exhortation: nothing can bring '
        'you peace but yourself; nothing can bring you peace but '
        'the triumph of principles. There is no "how to" here. '
        'The essay is a fist, not a manual. It does not tell you '
        'how to be self-reliant, it tells you that you already '
        'are, and that the only obstacle is the customs and '
        'conventions you keep letting other people install in '
        'you. A document of American individualism that has lost '
        'none of its charge in 180 years. Read it once in your '
        'twenties. Read it again in your forties. It will mean '
        'different things both times.',
  ),

  // ── 4. Can't Hurt Me ────────────────────────────────────────
  'cant_hurt_me': BookSummary(
    body:
        'Memoir of the only person to complete Navy SEAL '
        'training, Army Ranger School, and Air Force Tactical Air '
        'Controller training, and to run sixty-plus '
        'ultra-marathons. Goggins\'s central claim is the 40% '
        'rule: when your mind tells you you\'re done, you\'re only '
        'at 40% of what you can actually do. The book is '
        'autobiography plus training manual. The two are '
        'interleaved. The autobiography is the harder read: '
        'abusive childhood in rural Indiana and the projects of '
        'Buffalo, race in the SEAL pipeline, injuries, three '
        'Hell Weeks, weight-cutting for ranger school by running '
        'in the desert with a 50-pound vest on. The training '
        'manual is the easier read and the more useful one: the '
        'Accountable Mirror (writing down the worst thing about '
        'yourself every day and looking at it), the Cookie Jar '
        '(a mental archive of past hard things you survived, for '
        'the next time your brain tells you to quit), the callus '
        'concept (your mind is a muscle; the only way to grow it '
        'is to do the thing you don\'t want to do, repeatedly, '
        'until the resistance softens). The book is heavy on '
        'stories, light on theory. It will not change your mind. '
        'It will not argue with you. It is just Goggins, for '
        'three hundred pages, telling you what he did, and then '
        'telling you to do it. Take from it what you can.',
    chapters: [
      'I Should Have Been a Statistic',
      'Truth Hurts',
      'The Impossible Task',
      'Taking Souls',
      'Armored Mind',
      'It\'s Not About a Trophy',
      'The Most Powerful Weapon',
      'Talent Not Required',
      'Uncommon Amongst Uncommon',
      'The Empowerment of Failure',
      'What If?',
    ],
  ),

  // ── 5. The Way of Peace ─────────────────────────────────────
  'the_way_of_peace': BookSummary(
    body:
        'Allen\'s spiritual sequel to As a Man Thinketh, moving '
        'from the question of how to think to the question of '
        'how to live. Seven short chapters on meditation (the '
        'mystic ladder that reaches from earth to heaven), the '
        'two masters (self and truth, and the war between them), '
        'the acquirement of spiritual power, the realization of '
        'selfless love, entering into the infinite, saints sages '
        'and saviors, and the realization of perfect peace. '
        'Slightly more mystical than his earlier work, but the '
        'same short-chapter form, the same earnest tone, the '
        'same conviction that the work of self-perfection is the '
        'only work that matters. The book is best read in a '
        'quiet morning, slowly, one chapter a day. Do not try to '
        'consume it at speed — it loses coherence; the prose is '
        'thin and the ideas need to settle. The closing poem is '
        'the part to remember: "Hast thou crossed the wide '
        'ocean of strife? / Hast thou found on the Shores of the '
        'Silence, / Release from all the wild unrest of life?"',
    chapters: [
      'The Power of Meditation',
      'The Two Masters, Self and Truth',
      'The Acquirement of Spiritual Power',
      'The Realization of Selfless Love',
      'Entering into the Infinite',
      'Saints, Sages, and Saviors; The Law of Service',
      'The Realization of Perfect Peace',
    ],
  ),

  // ── 6. How to Live on 24 Hours a Day ─────────────────────────
  'how_to_live_24_hours': BookSummary(
    body:
        'A century-old productivity book that is still, somehow, '
        'the most useful one. Bennett\'s argument is simple: the '
        'average person has sixteen productive hours a week they '
        'are not using — they are scattered across morning and '
        'evening, and the day has to be carved back into them '
        'deliberately. The first half is the diagnosis: you think '
        'you are busy, but if you add up your "necessary" '
        'activity (work, commute, eating, dressing, errands), '
        'most days come out to four or five hours of work plus '
        'the rest. The second half is the prescription: use your '
        'morning for serious reading, your evening for serious '
        'study, and a couple of hours a week for cultivation '
        '("the use of the mind for its own improvement"). '
        'Bennett has no jargon, no apps, no system. He is the '
        'anti-GTD. The book is short, witty, and entirely free of '
        'the productivity-industrial complex that has since '
        'grown up around the same insight. The rare self-help '
        'book that respects the reader\'s intelligence.',
    chapters: [
      'The Daily Miracle',
      'The Desire to Exceed One\'s Self',
      'Where the Hours Go',
      'The Importance of Being a Fool',
      'Where to Find the Time',
      'Serious Reading',
      'Cultivation of a Hobby',
      'The Causes of Failure',
      'The Miraculous Power of Will',
      'Cultivating the Mind',
    ],
  ),

  // ── 7. The 48 Laws of Power ─────────────────────────────────
  'the_48_laws_of_power': BookSummary(
    body:
        'A catalogue of 48 laws of power, drawn from three '
        'thousand years of strategic literature — court memoirs, '
        'con-artists\' manuals, Talleyrand, Sun Tzu, Castiglione, '
        'Miyamoto Musashi, the Caesars, the Medicis. Greene is '
        'explicit that this is the dark side of strategy: how to '
        'conceal your intentions, court favor, outmaneuver '
        'rivals, never outshine the master, and crush your enemy '
        'totally. Half the laws are repugnant. The other half are '
        'clearly correct. Read it the way you would read a book '
        'on venomous snakes — to recognize the move when you see '
        'it. The most quoted book at Silicon Valley happy hours '
        'of the 2010s. One of the most cynical books ever to '
        'make a bestseller list. Almost certainly the most useful '
        'primer on the structure of social power ever published '
        'in English. The legal disclaimer (this is a study of '
        'power, not a manual) is in the introduction. Greene is '
        'serious. The book is dense, three hundred thousand words '
        'of it, and structured as 48 short essays, each '
        'illustrated with three or four historical anecdotes. '
        'Best read one law a day, in the morning, with a coffee. '
        'Do not read the whole thing in a weekend — it will make '
        'you insufferable, and you will not remember it.',
    chapters: [
      'Laws 1–10 (Never Outshine the Master, Never Put Too Much Trust in Friends, Conceal Your Intentions, Always Say Less Than Necessary, So Much Depends on Reputation, Court Attention at All Cost, Get Others to Do the Work, Make It Easy to Buy — Give Them Many Options, Win Through Actions, Never Through Argument)',
      'Laws 11–20 (Avoid the Unhappy and Unlucky, Learn to Keep People Dependent on You, Use Selective Honesty, Appeal to Self-Interest, Pose as a Friend Work as a Spy, Crush Your Enemy Totally, Use Absence, Cultivate an Air of Unpredictability, Do Not Build Fortresses, Know Who You\'re Dealing With)',
      'Laws 21–30 (Play a Sucker to Catch a Sucker, Use the Surrender Tactic, Concentrate Your Forces, Play the Perfect Courtier, Re-create Yourself, Put No Trust in Friends, Make Your Accomplishments Seem Effortless, Plan All the Way to the End, Make Your Accomplishments in Anticipation of Decline)',
      'Laws 31–40 (Control the Options, Play on People\'s Need to Believe, Discover Each Man\'s Thumbscrew, Think as You Like but Behave Like Others, Stay Royal to Your Tribe, Specialize, Strike the Shepherd and the Sheep Will Scatter, Create Compelling Spectacles, Think in Categories, Despise the Free Lunch)',
      'Laws 41–48 (Avoid Stepping into a Great Man\'s Shoes, Strike the Past, Hold Court, Master the Art of Timing, Command Attention, Transmute Everything into Gold, Assume Formlessness, Seal Your Own Fate)',
    ],
  ),

  // ── 8. Thinking, Fast and Slow ──────────────────────────────
  'thinking_fast_and_slow': BookSummary(
    body:
        'A Nobel laureate\'s accessible summary of his life\'s '
        'work on the two systems of thought. System 1 is fast, '
        'intuitive, prone to bias; System 2 is slow, deliberate, '
        'lazy. The book\'s project is to name the heuristics '
        '(anchoring, availability, representativeness, '
        'prospect theory, framing), show you where they lead you '
        'astray, and demonstrate that the mind you trust to make '
        'sense of the world is mostly making confident guesses. '
        'WYSIATI — What You See Is All There Is — is the concept '
        'that stays with you. The mind does not naturally '
        'represent what is absent; it overweights what is in '
        'front of it; it substitutes an easy question for a hard '
        'one. Not a self-help book. A textbook that, if you read '
        'it, will quietly dismantle most of your intuitions about '
        'your own rationality. The prose is careful, even slow, '
        'with Kahneman building each argument on the one before. '
        'It is the longest-feeling 400 pages you will read this '
        'year, and the most rewarding. Read it once, slowly, and '
        'expect to spend six months noticing the bias at the '
        'moment it happens to you. That is the point.',
    chapters: [
      'Part I: Two Systems',
      'Part II: Heuristics and Biases',
      'Part III: Overconfidence',
      'Part IV: Choices',
      'Part V: Two Selves (the experiencing self vs the remembering self)',
    ],
  ),

  // ── 9. Rich Dad Poor Dad ────────────────────────────────────
  'rich_dad_poor_dad': BookSummary(
    body:
        'Kiyosaki\'s two-fathers frame is too clean to be quite '
        'real, but the book is genuinely useful. The poor dad '
        '(his real father, PhD, "A" student, federal employee) '
        'and the rich dad (his best friend\'s father, school '
        'dropout, real estate investor) give him two '
        'contradictory views of money, and he had to think for '
        'himself about which was right. The core lesson: the rich '
        'don\'t work for money; they make money work for them. '
        'The cashflow quadrant (Employee, Self-employed, '
        'Business owner, Investor) is a useful mental model for '
        'figuring out which side of the table you\'re on. The '
        'book oversimplifies and leans on motivational '
        'punch-lines ("the single most powerful asset we all have '
        'is our mind"). The underlying point — that financial '
        'literacy is the missing subject in modern education — '
        'has aged well. Read it as a vocabulary lesson, not a '
        'system. The vocabulary (assets, liabilities, cashflow, '
        'passive income) is the part that lasts. The specific '
        'advice (buy real estate, avoid W-2 income) is dated.',
    chapters: [
      'Lesson 1: The Rich Don\'t Work for Money',
      'Lesson 2: Why Teach Financial Literacy',
      'Lesson 3: Mind Your Own Business',
      'Lesson 4: The History of Taxes and the Power of Corporations',
      'Lesson 5: The Rich Invent Money',
      'Lesson 6: Work to Learn — Don\'t Work for Money',
      'Overcoming Obstacles',
      'Getting Started',
      'Still Want More?',
    ],
  ),

  // ── 10. Mastery ─────────────────────────────────────────────
  'mastery': BookSummary(
    body:
        'Greene\'s sequel to The 48 Laws of Power is a study of '
        'the long, lonely path to mastery, and it is a better '
        'book. Five sections: discover your calling (the Life\'s '
        'Task), submit to reality (the apprenticeship), absorb '
        'the master\'s power (the mentor dynamic), see people as '
        'they are (social intelligence), awaken the dimensional '
        'mind (creativity). Backed by case studies of Darwin, '
        'Einstein, Mozart, da Vinci, Paul Graham, and many '
        'others. The book\'s central claim is that genius is not '
        'a gift but a process, and that the process is available '
        'to anyone willing to put in the time. The deeper claim '
        'is more interesting: most people fail to reach mastery '
        'not for lack of talent but for lack of contact with '
        'reality. They substitute their preferences for the '
        'demands of the field. They avoid pain. They confuse '
        'motion for progress. The book is more constructive than '
        'The 48 Laws. The takeaway is that mastery is achievable '
        'if you are willing to be patient, persistent, and '
        'slightly obsessed. Greene\'s prose is heavy in places — '
        'the case studies of Mozart\'s father come to mind — but '
        'the underlying argument is sound.',
    chapters: [
      'I. Discover Your Calling (The Life\'s Task)',
      'II. Submit to Reality (The Ideal Apprenticeship)',
      'III. Absorb the Master\'s Power (The Mentor Dynamic)',
      'IV. See People as They Are (Social Intelligence)',
      'V. Awaken the Dimensional Mind (The Creative-Active)',
    ],
  ),

  // ── 11. The Psychology of Money ─────────────────────────────
  'psychology_of_money': BookSummary(
    body:
        'Housel\'s premise: doing well with money has little to '
        'do with how smart you are and a lot to do with how you '
        'behave. Twenty short chapters, each a story: a janitor '
        'who left $8M, a Merrill Lynch executive who went broke, '
        'a tech exec who threw gold coins into the ocean, a '
        'farmer who sat on his land for fifty years, a hedge '
        'fund manager who lost it all. The recurring insight is '
        'that wealth is what you don\'t see — a $5M net worth '
        'and a $5M lifestyle look the same on Instagram but feel '
        'very different at retirement. The book\'s behavioral '
        'lessons: room for error (the most important part of '
        'every plan is the part that allows you to be wrong), '
        'reasonable > rational (the optimal strategy is the one '
        'you can actually stick to), tails you win (the biggest '
        'financial gains come from the rare events you can\'t '
        'predict), and freedom (the only money goal worth '
        'pursuing is the point at which your time is your own). '
        'The single most useful personal finance book of the '
        'last decade. Reads in an afternoon. Will save you years '
        'of compounding mistakes.',
    chapters: [
      'No Man\'s Story Is the Same',
      'Luck and Risk',
      'Never Enough',
      'Confounding Compounding',
      'Getting Wealthy vs. Staying Wealthy',
      'Tails, You Win',
      'Freedom',
      'Man in the Car Paradox',
      'Wealth is What You Don\'t See',
      'Save Money',
      'Reasonable > Rational',
      'Surprise!',
      'Room for Error',
      'You\'ll Change',
      'Nothing\'s Free',
      'You & Me',
      'The Seduction of Pessimism',
      'When You\'ll Believe Anything',
      'All Together Now',
      'Confessions',
    ],
  ),

  // ── 12. Atomic Habits ───────────────────────────────────────
  'atomic_habits': BookSummary(
    body:
        'Clear\'s argument is that small habits compound into '
        'remarkable results. The Four Laws of Behavior Change '
        'are the framework: make it obvious (cue), make it '
        'attractive (craving), make it easy (response), make it '
        'satisfying (reward). The book is practical, '
        'evidence-based, and full of techniques that actually '
        'work: habit stacking (attach a new habit to an existing '
        'one — "after I pour my coffee, I will meditate for one '
        'minute"), environment design (make the cue visible, '
        'hide the friction), the two-minute rule (start so small '
        'you can\'t say no — "read one page" rather than "read '
        'for thirty minutes"), identity-based habits (focus on '
        'who you want to be, not what you want to do — "I am a '
        'runner" rather than "I want to run"). The book is a '
        'more readable and evidence-rich update of The Power of '
        'Habit, and a better entry point. The middle section on '
        'the Four Laws is the most quotable, but the late '
        'section on "advanced tactics" — the Goldilocks rule '
        '(motivation peaks when a task is right at the edge of '
        'your ability), the downsides of creating good habits '
        '(they can crowd out the great), how to recover from a '
        'broken streak — is the part that will actually change '
        'your behavior. A modern classic in the field.',
    chapters: [
      'The Fundamentals: Why Tiny Changes Make a Big Difference',
      'Law 1: Make It Obvious',
      'Law 2: Make It Attractive',
      'Law 3: Make It Easy',
      'Law 4: Make It Satisfying',
      'Advanced Tactics: How to Go from Being Merely Good to Being Truly Great',
    ],
  ),
};

/// Look up the summary for a book. Returns null if the book
/// doesn't have a hand-written summary (which would be a bug —
/// every book in the catalog should have one). The reader falls
/// back to the card blurb if this returns null.
BookSummary? summaryFor(Book book) => kBookSummaries[book.id];
