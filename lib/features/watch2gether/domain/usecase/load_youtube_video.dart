import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/core/usecase/usecase.dart';
import 'package:chat_application/core/utils/youtube_url_parser.dart';
import 'package:chat_application/features/watch2gether/domain/entity/youtube_video_data.dart';
import 'package:fpdart/fpdart.dart';

class LoadYoutubeVideo implements UseCase<YoutubeVideoData, String> {
  @override
  Future<Either<Failure, YoutubeVideoData>> call(String url) async {
    final parsed = YoutubeUrlParser.parse(url);
    if (parsed == null) {
      return left(Failure('Invalid YouTube URL'));
    }
    return right(YoutubeVideoData(
      videoId: parsed.videoId,
      originalUrl: parsed.originalUrl,
      normalizedUrl: parsed.normalizedUrl,
      thumbnailUrl: parsed.thumbnailUrl,
    ));
  }
}
