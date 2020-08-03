/// Represents a SSH-Command
class Command {
    /// ID for Database
    int id;

    /// ID of the profile the command belongs to
    int profileId;

    /// The actual SSH-Command
    String commandMessage;

    String caption;

    /// Ctor for Commands
    Command(String msg) {
        this.commandMessage = msg;
    }

    /// Converts data from Database into Command.
    static Command fromMap(Map<String, dynamic> map) {
        return _fromDatabase(
            map["id"],
            map["profileId"],
            map["commandMessage"],
            map["caption"]
        );
    }

    /// Constructor for Commands by the Database.
    static Command _fromDatabase(int id, int profileId, String commandMessage, String caption) {
        Command cmd = new Command(commandMessage);

        cmd.id = id;
        cmd.profileId = profileId;
        cmd.caption = caption;

        return cmd;
    }

    /// Converts the object into a map for storing it into the database.
    Map<String, dynamic> toMap() {
        return {
            "id" : this.id,
            "profileId" : this.profileId,
            "commandMessage" : this.commandMessage,
            "caption" : this.caption
        };
    }
}