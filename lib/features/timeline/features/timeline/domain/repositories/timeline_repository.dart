import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/features/timeline/features/timeline/domain/entities/event.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class TimelineRepository {
  Future<Either<Failure,List<Event>>> getEvents({
    required String userId,
    required String receiverId,
  });

  Future<Either<Failure,List<Event>>> refreshAndfetchEvents({
    required String userId,
    required String receiverId,
  });
}