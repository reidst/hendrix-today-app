import 'package:flutter/material.dart' show DateUtils;

import 'package:hendrix_today_app/objects/event_type.dart';

import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:intl/intl.dart' show DateFormat;

/// A data structure for all types of Hendrix Today items.
///
/// All event data is originally created by a user submitting an event proposal
/// via online form, with some intermediary human moderation between the form
/// and the Firestore database from which this app pulls event data. Because of
/// both this and the loose Firestore document content type system, [Event]
/// creation needs to be flexible; this is handled by the [fromFirebase] static
/// method.
///
/// The rest of this class's contents are various display and sorting/filtering
/// methods for UI/UX uses.
class Event {
  /// The title of the event; a necessary field.
  ///
  /// This tends to be a short string.
  final String title;

  /// A more detailed description of the event; a necessary field.
  ///
  /// This can be as long as necessary, but tends to be around a few hundred
  /// characters. Descriptions also support hyperlinks in the form of HTML `<a>`
  /// tags with `href` attributes; for example, the raw description
  /// `'hello <a href=https://pub.dev>world</a>!'` would ultimately behave the
  /// same as the following Markdown example:
  ///
  /// hello [world](https://pub.dev)!
  final String desc;

  /// The type of this submission/event item; a necessary field.
  final EventType eventType;

  /// The date on which this event occurs and on which this event will appear on
  /// the calendar; a necessary field.
  ///
  /// No time data is stored here. If the event or meeting occurs on multiple
  /// days, this date will represent the first day on which it occurs.
  final DateTime date;

  /// The time this event occurs; an optional field.
  ///
  /// This field can be used as a short description for when the event occurs,
  /// especially in the case where an event/meeting occurs on multiple dates or
  /// times.
  final String? time;

  /// The location for this event; an optional field.
  final String? location;

  /// The official contact for the event; a necessary field.
  ///
  /// This information is not displayed anywhere in the app.
  final String contactName;

  /// The official contact email address; a necessary field.
  ///
  /// If a user wishes to contact an event/announcement's official contact, this
  /// address will be conveniently available.
  final String contactEmail;

  /// The first date on which this event will appear on the home page; a
  /// necessary field.
  final DateTime beginPosting;

  /// The last date on which this event will appear on the home page; a
  /// necessary field.
  final DateTime endPosting;

  /// A general-purpose day-precision deadline for this event; an optional
  /// field.
  final DateTime? applyDeadline;

  /// A list of descriptive words that describe this event; a necessary field.
  ///
  /// The strings in this list should be part of a small collection of
  /// pre-approved tags to aid in search convenience. Although this field is
  /// necessary, an empty list is valid.
  final List<String> tags;

  /// Default [Event] constructor.
  ///
  /// When constructing events from Firebase data, please consider using the
  /// [fromFirebase] static method.
  Event({
    required this.title,
    required this.desc,
    required this.eventType,
    required this.date,
    required this.time,
    required this.location,
    required this.contactName,
    required this.contactEmail,
    required this.beginPosting,
    required this.endPosting,
    required this.applyDeadline,
    required this.tags,
  });

  /// Can be used to sort [Event]s by [date].
  int compareByDate(Event other) => date.compareTo(other.date);

  /// Converts Firebase data into an [Event].
  ///
  /// The return value will be `null` if the given data is invalid:
  /// * Titles and descriptions may not be `null`.
  /// * [EventType]s may not be `null` and must be translatable from a string (via
  /// [EventType.fromString]).
  /// * Dates may not be `null`.
  /// * Contact names and emails may not be `null`.
  /// * [beginPosting] and [endPosting] dates may not be `null`.
  static Event? fromFirebase(Map<String, dynamic> data) {
    // Convenient caster: https://stackoverflow.com/a/67435226
    T? cast<T>(dynamic x) => (x is T) ? x : null;

    final String? maybeTitle = cast(data["title"]);
    if (maybeTitle == null) return null;
    final String title = maybeTitle;

    final String? maybeDesc = cast(data["desc"]);
    if (maybeDesc == null) return null;
    final String desc = maybeDesc;

    final EventType? maybeEventType = EventType.fromString(data["type"]);
    if (maybeEventType == null) return null;
    final EventType eventType = maybeEventType;

    final Timestamp? maybeDate = cast(data["date"]);
    if (maybeDate == null) return null;
    final DateTime date = maybeDate.toDate();

    final String? time = cast(data["time"]);
    final String? location = cast(data["location"]);

    final String? maybeContactName = cast(data["contactName"]);
    if (maybeContactName == null) return null;
    final String contactName = maybeContactName;

    final String? maybeContactEmail = cast(data["contactEmail"]);
    if (maybeContactEmail == null) return null;
    final String contactEmail = maybeContactEmail;

    final Timestamp? maybeBeginPosting = cast(data["beginPosting"]);
    if (maybeBeginPosting == null) return null;
    final DateTime beginPosting = maybeBeginPosting.toDate();

    final Timestamp? maybeEndPosting = cast(data["endPosting"]);
    if (maybeEndPosting == null) return null;
    final DateTime endPosting = maybeEndPosting.toDate();

    final DateTime? applyDeadline =
        cast<Timestamp>(data["applyDeadline"])?.toDate();

    final List<String> tags = (cast<String>(data["tags"]) ?? "").split(';');

    return Event(
      title: title,
      desc: desc,
      eventType: eventType,
      date: date,
      time: time,
      location: location,
      contactName: contactName,
      contactEmail: contactEmail,
      beginPosting: beginPosting,
      endPosting: endPosting,
      applyDeadline: applyDeadline,
      tags: tags,
    );
  }

  /// Formats the [date] in a human-readable form.
  ///
  /// Example: `2023-06-14` becomes `Wed, Jun 14, 2023`
  String displayDate() => DateFormat('EEE, MMM d, yyyy').format(date);

  /// Formats the [applyDeadline] in a human-readable form.
  ///
  /// Returns `null` if the deadline is `null`.
  ///
  /// Example: `2023-06-14` becomes `Wed, Jun 14, 2023`
  String? displayDeadline() => applyDeadline == null
      ? null
      : DateFormat('EEE, MMM d, yyyy').format(applyDeadline!);

  /// Checks if [searchQuery] appears in the [title] or [desc]
  /// (case-insensitive).
  bool containsString(String searchQuery) =>
      title.toLowerCase().contains(searchQuery.toLowerCase()) |
      desc.toLowerCase().contains(searchQuery.toLowerCase());

  /// Checks if [date] is the same day as [match].
  bool matchesDate(DateTime match) => DateUtils.isSameDay(date, match);

  /// Checks if [day] falls between [beginPosting] and [endPosting] (including
  /// those start and end dates).
  bool inPostingRange(DateTime day) =>
      DateUtils.isSameDay(day, beginPosting) ||
      DateUtils.isSameDay(day, endPosting) ||
      (day.isAfter(beginPosting) && day.isBefore(endPosting));
}
