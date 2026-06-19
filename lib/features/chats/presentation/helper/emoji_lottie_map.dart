import 'package:emoji_regex/emoji_regex.dart';

class EmojiLottieConfig {
  final String bundledAsset;
  final String? networkUrl;
  const EmojiLottieConfig(this.bundledAsset, {this.networkUrl});
}

const Map<String, EmojiLottieConfig> emojiLottieMap = {
  // === Original 28 (keep current) ===
  '❤️': EmojiLottieConfig('assets/animations/heart.json'),
  '🔥': EmojiLottieConfig('assets/animations/fire.json'),
  '👍': EmojiLottieConfig('assets/animations/thumbs_up.json'),
  '👎': EmojiLottieConfig('assets/animations/thumbs_down.json'),
  '🥳': EmojiLottieConfig('assets/animations/party.json'),
  '🎉': EmojiLottieConfig('assets/animations/confetti.json'),
  '😢': EmojiLottieConfig('assets/animations/cry.json'),
  '😂': EmojiLottieConfig('assets/animations/tears_of_joy.json'),
  '😍': EmojiLottieConfig('assets/animations/drool.json'),
  '💯': EmojiLottieConfig('assets/animations/full_score.json'),
  '😮': EmojiLottieConfig('assets/animations/astonished.json'),
  '🎆': EmojiLottieConfig('assets/animations/fireworks.json'),
  '😊': EmojiLottieConfig('assets/animations/happy.json'),
  '😭': EmojiLottieConfig('assets/animations/sob.json'),
  '😡': EmojiLottieConfig('assets/animations/angry.json'),
  '🥰': EmojiLottieConfig('assets/animations/hearts.json'),
  '😘': EmojiLottieConfig('assets/animations/throwing-kiss.json'),
  '😱': EmojiLottieConfig('assets/animations/screaming.json'),
  '🤔': EmojiLottieConfig('assets/animations/thinking.json'),
  '🙏': EmojiLottieConfig('assets/animations/worship.json'),
  '👏': EmojiLottieConfig('assets/animations/clap.json'),
  '🎂': EmojiLottieConfig('assets/animations/birthday-cake.json'),
  '🎈': EmojiLottieConfig('assets/animations/balloon.json'),
  '💔': EmojiLottieConfig('assets/animations/broken-heart.json'),
  '✨': EmojiLottieConfig('assets/animations/glowing-star.json'),
  '🥺': EmojiLottieConfig('assets/animations/plead.json'),
  '😴': EmojiLottieConfig('assets/animations/sleeping.json'),
  '🤮': EmojiLottieConfig('assets/animations/puke.json'),

  // === New: Face emojis — positive ===
  '😀': EmojiLottieConfig('assets/animations/grinning.json'),
  '😁': EmojiLottieConfig('assets/animations/beam.json'),
  '🤣': EmojiLottieConfig('assets/animations/roll.json'),
  '😄': EmojiLottieConfig('assets/animations/smiling-eyes.json'),
  '😅': EmojiLottieConfig('assets/animations/sweat.json'),
  '😆': EmojiLottieConfig('assets/animations/squint.json'),
  '😉': EmojiLottieConfig('assets/animations/wink.json'),
  '😋': EmojiLottieConfig('assets/animations/delicious.json'),
  '😌': EmojiLottieConfig('assets/animations/relieved.json'),
  '😎': EmojiLottieConfig('assets/animations/cool.json'),
  '😏': EmojiLottieConfig('assets/animations/smirking.json'),
  '🙂': EmojiLottieConfig('assets/animations/smile.json'),
  '🤩': EmojiLottieConfig('assets/animations/star-eye.json'),
  '🤪': EmojiLottieConfig('assets/animations/zany.json'),
  '🤠': EmojiLottieConfig('assets/animations/cowboy.json'),
  '🥲': EmojiLottieConfig('assets/animations/gratitude.json'),

  // === New: Face emojis — neutral / negative ===
  '🙁': EmojiLottieConfig('assets/animations/frown.json'),
  '😞': EmojiLottieConfig('assets/animations/sad.json'),
  '😟': EmojiLottieConfig('assets/animations/worried.json'),
  '😔': EmojiLottieConfig('assets/animations/pensive.json'),
  '😕': EmojiLottieConfig('assets/animations/confused.json'),
  '🙃': EmojiLottieConfig('assets/animations/upside-down.json'),
  '😐': EmojiLottieConfig('assets/animations/neutral.json'),
  '😑': EmojiLottieConfig('assets/animations/expressionless.json'),
  '😒': EmojiLottieConfig('assets/animations/side-eye.json'),
  '😓': EmojiLottieConfig('assets/animations/downcast.json'),
  '😥': EmojiLottieConfig('assets/animations/relief.json'),
  '😨': EmojiLottieConfig('assets/animations/fearful.json'),
  '😰': EmojiLottieConfig('assets/animations/anxious.json'),
  '😳': EmojiLottieConfig('assets/animations/flushed.json'),
  '😲': EmojiLottieConfig('assets/animations/amazement.json'),
  '😵': EmojiLottieConfig('assets/animations/dizzy.json'),
  '😶': EmojiLottieConfig('assets/animations/speechlessness.json'),
  '😬': EmojiLottieConfig('assets/animations/grimacing.json'),
  '🤥': EmojiLottieConfig('assets/animations/lying.json'),
  '🤤': EmojiLottieConfig('assets/animations/glutton.json'),
  '🤢': EmojiLottieConfig('assets/animations/nauseated.json'),
  '🤧': EmojiLottieConfig('assets/animations/sneezing.json'),
  '😖': EmojiLottieConfig('assets/animations/confounded.json'),
  '😤': EmojiLottieConfig('assets/animations/scold.json'),
  '😣': EmojiLottieConfig('assets/animations/persevere.json'),
  '😫': EmojiLottieConfig('assets/animations/tired.json'),
  '😩': EmojiLottieConfig('assets/animations/weary.json'),
  '😪': EmojiLottieConfig('assets/animations/sleepy.json'),
  '😯': EmojiLottieConfig('assets/animations/hushed.json'),
  '🤐': EmojiLottieConfig('assets/animations/zipper.json'),
  '🥱': EmojiLottieConfig('assets/animations/yawning.json'),
  '🤭': EmojiLottieConfig('assets/animations/omg.json'),
  '🤫': EmojiLottieConfig('assets/animations/shushing.json'),
  '🙄': EmojiLottieConfig('assets/animations/rolling-eyes.json'),
  '🤨': EmojiLottieConfig('assets/animations/raised-eyebrow.json'),
  '🤯': EmojiLottieConfig('assets/animations/mind-blown.json'),
  '🫠': EmojiLottieConfig('assets/animations/melted.json'),
  '🫡': EmojiLottieConfig('assets/animations/salute.json'),

  // === New: Face emojis — unusual / special ===
  '😇': EmojiLottieConfig('assets/animations/halo.json'),
  '👿': EmojiLottieConfig('assets/animations/demon.json'),
  '👽': EmojiLottieConfig('assets/animations/alien.json'),
  '🥸': EmojiLottieConfig('assets/animations/disguised.json'),
  '🤑': EmojiLottieConfig('assets/animations/money.json'),
  '🥵': EmojiLottieConfig('assets/animations/hot.json'),
  '🥶': EmojiLottieConfig('assets/animations/cold.json'),
  '🥴': EmojiLottieConfig('assets/animations/drunk.json'),

  // === New: Hand gestures ===
  '👌': EmojiLottieConfig('assets/animations/ok.json'),
  '✌️': EmojiLottieConfig('assets/animations/victory.json'),
  '👋': EmojiLottieConfig('assets/animations/wave.json'),
  '💪': EmojiLottieConfig('assets/animations/muscle.json'),
  '👐': EmojiLottieConfig('assets/animations/open-hands.json'),
  '👆': EmojiLottieConfig('assets/animations/pointing-up.json'),
  '👇': EmojiLottieConfig('assets/animations/pointing-down.json'),

  // === New: Health / medical ===
  '🤒': EmojiLottieConfig('assets/animations/thermometer.json'),
  '🤕': EmojiLottieConfig('assets/animations/head-bandage.json'),
  '😷': EmojiLottieConfig('assets/animations/sick.json'),

  // === New: Hearts ===
  '💓': EmojiLottieConfig('assets/animations/beating-heart.json'),
  '💗': EmojiLottieConfig('assets/animations/pink-heart.json'),
  '💝': EmojiLottieConfig('assets/animations/gift-heart.json'),
  '💘': EmojiLottieConfig('assets/animations/cupid.json'),
  '❤️‍🔥': EmojiLottieConfig('assets/animations/fire-heart.json'),
  '❤️‍🩹': EmojiLottieConfig('assets/animations/bandaged-heart.json'),

  // === New: Objects & symbols ===
  '☕': EmojiLottieConfig('assets/animations/coffee.json'),
  '🍺': EmojiLottieConfig('assets/animations/beers.json'),
  '🍾': EmojiLottieConfig('assets/animations/champagne.json'),
  '🥂': EmojiLottieConfig('assets/animations/clinking.json'),
  '🍷': EmojiLottieConfig('assets/animations/wine.json'),
  '✅': EmojiLottieConfig('assets/animations/correct.json'),
  '❌': EmojiLottieConfig('assets/animations/wrong.json'),
  '❓': EmojiLottieConfig('assets/animations/question.json'),
  '❗': EmojiLottieConfig('assets/animations/exclamation.json'),
  '🔔': EmojiLottieConfig('assets/animations/bell.json'),
  '🔪': EmojiLottieConfig('assets/animations/knife.json'),
  '💣': EmojiLottieConfig('assets/animations/bomb.json'),
  '🎮': EmojiLottieConfig('assets/animations/game.json'),
  '📷': EmojiLottieConfig('assets/animations/camera.json'),
  '🎓': EmojiLottieConfig('assets/animations/graduate.json'),
  '🧨': EmojiLottieConfig('assets/animations/firecracker.json'),
  '🌈': EmojiLottieConfig('assets/animations/rainbow.json'),
  '🎁': EmojiLottieConfig('assets/animations/gift.json'),
  '🎯': EmojiLottieConfig('assets/animations/direct-hit.json'),
  '🚀': EmojiLottieConfig('assets/animations/rocket.json'),
  '🌹': EmojiLottieConfig('assets/animations/rose.json'),
  '🥀': EmojiLottieConfig('assets/animations/wilt.json'),
  '🚩': EmojiLottieConfig('assets/animations/flag.json'),
  '⚡': EmojiLottieConfig('assets/animations/electricity.json'),
  '💧': EmojiLottieConfig('assets/animations/droplet.json'),
  '👄': EmojiLottieConfig('assets/animations/lips.json'),
  '💋': EmojiLottieConfig('assets/animations/kiss.json'),
  '👀': EmojiLottieConfig('assets/animations/eyes.json'),
  '💸': EmojiLottieConfig('assets/animations/money-wing.json'),
};

EmojiLottieConfig? getLottieForEmoji(String text) {
  final regex = emojiRegex();
  final matches = regex.allMatches(text).toList();
  if (matches.length != 1) return null;
  final emoji = matches.first.group(0)!;
  return emojiLottieMap[emoji];
}
