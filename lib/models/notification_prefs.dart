/// Which kinds of notification a member wants to receive.
class NotificationPrefs {
  NotificationPrefs({
    this.announcementsOn = true,
    this.messagesOn = true,
    this.calendarOn = true,
    this.listsOn = true,
    this.commentsOn = true,
    this.reactionsOn = true,
    this.communityOn = true,
  });

  bool announcementsOn;
  bool messagesOn;
  bool calendarOn;
  bool listsOn;
  bool commentsOn;
  bool reactionsOn;
  bool communityOn;
}
