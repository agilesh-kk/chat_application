//handles all the expection messages
class ServerExceptions implements Exception{
  final String message;
  const ServerExceptions(this.message);
}