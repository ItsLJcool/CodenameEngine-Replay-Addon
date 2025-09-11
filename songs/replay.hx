//a
if (PlayState.chartingMode) return disableScript();
import Date;
if (REPLAY_MANAGER.SHOULD_PLAYBACK) {
    var prev_validScore = PlayState.instance.validScore;
    PlayState.instance.validScore = false;
    if (REPLAY_MANAGER.USE_CONDUCTOR) REPLAY_MANAGER.playback();
    else function onSongStart() { REPLAY_MANAGER.playback(); }
    function destroy() {
        PlayState.instance.validScore = prev_validScore;
        REPLAY_MANAGER.stop();
    }

    if (REPLAY_MANAGER.USE_CONDUCTOR) function onGamePause(e) {
        if (REPLAY_MANAGER.PLAYBACK_EVENTS.length == 0) return;
        e.cancel();
    }

    var events_ended:Bool = false;
    function update(elapsed) {
        if (events_ended) return;
        if (REPLAY_MANAGER.PLAYBACK_EVENTS.length != 0) return;
        events_ended = true;
        trace("Events Ended");
    }

    return;
}
if (!FlxG.save.data.recordEnabled) return;

if (REPLAY_MANAGER.USE_CONDUCTOR) REPLAY_MANAGER.record();
else function onSongStart() { REPLAY_MANAGER.record(); }

function onSongEnd() {
    REPLAY_MANAGER.stop();
    var name = StringTools.replace(Date.now().toString(), ":", "-");
    var folder = PlayState.SONG.meta.name+"/"+PlayState.difficulty;
    if (PlayState.variation != null) folder += "/"+PlayState.variation;
    REPLAY_MANAGER.saveReplay(folder, name);
}